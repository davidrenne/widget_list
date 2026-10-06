require 'cgi'

module WidgetList

  class Utils

    def self.numeric?(object)
      true if Float(object) rescue false
    end

    def self.date?(object)
      true if Date.parse(object) rescue false
    end

    #JsonEncode
    def self.json_encode(arr,return_string = false)
      if return_string
        p JSON.generate(arr)
      else
        JSON.generate(arr)
      end
    end

    #BuildQueryString
    def self.build_query_string(args)
      q = []
      args.each { |k,v|
        if v.is_a?(Hash) || v.respond_to?(:to_unsafe_h)
          q << {k => (v.respond_to?(:to_unsafe_h) ? v.to_unsafe_h : v)}.to_query
        else
          q << k.to_s + '=' + CGI.escape(v.to_s)
        end
      }
      q.join('&')
    end


    #BuildUrl
    def self.build_url(page='',args = {}, append_get=false)
      qs = build_query_string(args)
      getvars = ''
      if append_get && WidgetList::RequestContext.request
        getvars = build_query_string(WidgetList::RequestContext.request)
      end

      unless page =~ /\?/
        "#{page}?" + qs + '&' + getvars
      else
        "#{page}" + qs + '&' + getvars
      end
    end

    #Fill
    def self.fill(tags = {}, template = '')
      tpl = template.dup
      tags.each { |k,v|
        tpl = tpl.gsub(k.to_s) { v.to_s }
      }
      tpl
    end

    #test_all
    def self.test_all
      output_final = ''
      output_final += "JsonEncode\n<br/>\n<br/>"

      a = { }
      a['asdfasdf'] = 'asfd'
      a[:test] = 1234
      a[2153125] = nil
      output_final += Utils.json_encode(a)


      output_final += "\n<br/>\n<br/>BuildQueryString\n<br/>\n<br/>"

      a = { }
      a['asdfasdf'] = 'asdf asdfj ajskdfhasdf'
      a['dave'] = 'a)(J#(*J@T2p2kfasdfa fas %20fj ajskdfhasdf'
      output_final += Utils.build_query_string(a)


      output_final += "\n<br/>\n<br/>BuildUrl\n<br/>\n<br/>"


      output_final += Utils.build_url('page.php?',a)


      output_final += "\n<br/>\n<br/>Fill\n<br/>\n<br/>"

      output_final += Utils.fill({'<!--CONTENT-->'=>'dave','<!--TITLE-->'=>'the title'},'<!--TITLE--> ---------   <!--CONTENT-->')
    end

  end

end
