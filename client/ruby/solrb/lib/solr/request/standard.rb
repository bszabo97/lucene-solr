# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Solr
  module Request
    class Standard < Solr::Request::Select

      VALID_PARAMS = [:query, :sort, :default_field, :operator, :start, :rows,
        :filter_queries, :field_list, :debug_query, :explain_other, :facets]
      
      def initialize(params)
        super('standard')
        
        raise "Invalid parameters: #{(params.keys - VALID_PARAMS).join(',')}" unless 
          (params.keys - VALID_PARAMS).empty?
        
        raise ":query parameter required" unless params[:query]
        
        @params = params.dup
        
        # Validate operator
        if params[:operator]
          raise "Only :and/:or operators allowed" unless 
            [:and, :or].include?(params[:operator])
            
          @params[:operator] = params[:operator].to_s.upcase
        end

        # Validate start, rows can be transformed to ints
        @params[:start] = params[:start].to_i if params[:start]
        @params[:rows] = params[:rows].to_i if params[:rows]
        
        @params[:field_list] ||= ["*","score"]

        #TODO model highlighting parameters: http://wiki.apache.org/solr/HighlightingParameters
      end
      
      def to_hash
        hash = {}
        
        # standard request param processing
        sort = @params[:sort].collect do |sort|
          key = sort.keys[0]
          "#{key.to_s} #{sort[key] == :descending ? 'desc' : 'asc'}"
        end.join(',') if @params[:sort]
        hash[:q] = sort ? "#{@params[:query]};#{sort}" : @params[:query]
        hash["q.op"] = @params[:operator]
        hash[:df] = @params[:default_field]

        # common parameter processing
        hash[:start] = @params[:start]
        hash[:rows] = @params[:rows]
        hash[:fq] = @params[:filter_queries]
        hash[:fl] = @params[:field_list].join(',')
        hash[:debugQuery] = @params[:debug_query]
        hash[:explainOther] = @params[:explain_other]
        
        # facet parameter processing
        if @params[:facets]
          # TODO need validation of all that is under the :facets Hash too
          hash[:facet] = true
          hash["facet.field"] = []
          hash["facet.query"] = @params[:facets][:queries]
          hash["facet.sort"] = (@params[:facets][:sort] == :count) if @params[:facets][:sort]
          hash["facet.limit"] = @params[:facets][:limit]
          hash["facet.missing"] = @params[:facets][:missing]
          hash["facet.mincount"] = @params[:facets][:mincount]
          hash["facet.prefix"] = @params[:facets][:prefix]
          @params[:facets][:fields].each do |f|
            if f.kind_of? Hash
              key = f.keys[0]
              value = f[key]
              hash["facet.field"] << key
              hash["f.#{key}.facet.sort"] = (value[:sort] == :count) if value[:sort]
              hash["f.#{key}.facet.limit"] = value[:limit]
              hash["f.#{key}.facet.missing"] = value[:missing]
              hash["f.#{key}.facet.mincount"] = value[:mincount]
              hash["f.#{key}.facet.prefix"] = value[:prefix]
            else
              hash["facet.field"] << f
            end
          end
        end
        
        hash.merge(super.to_hash)
      end

    end
  end
end
