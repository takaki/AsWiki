# Copyritght (c) 2002 TANIGUCHI Takaki
# This program is distributed under the GNU GPL 2 or later.

require 'amrita/merge'

module AsWiki
  class MergeTemplateFile < Amrita::MergeTemplate
    def initialize(template, dir=nil, &block)
      @template = template
      super(dir, &block)
    end

    def amrita_expand_element(e, context)
      case e.hid
      when /template#(.*)/
        data_id = $1
        e = merge_templates(@template, data_id, e, context)
      else
        e.init_body do
          e.body.expand1(self, context)
        end
      end

      if @body
        e.expand(@body, context)
      else
        e
      end
    end
  end
end

