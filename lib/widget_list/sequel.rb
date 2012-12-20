module Sequel
  class Database
    @final_results = {}
    attr_accessor :final_results

    @errors = false
    attr_accessor :errors

    @last_error = ''
    attr_accessor :last_error

    @final_count = 0
    attr_accessor :final_count

    @last_sql = ''
    attr_accessor :last_sql

    def _convert_bind(bind=[])
      parameters = ''
      unless bind.empty?
        all = []
        (bind||{}).each { |v|
          if v.class.name.downcase == 'string'
            all << "'" + v.gsub(/'/,"\\\\'") + "'"
          else
            all << v
          end
        }
        parameters = "," + all.join(' ,')
      end
      parameters
    end

    # _exec, pass a block and iterate the total rows
    #
    # example
    #
=begin
     $DATABASE._exec {|i|
       asdf  = "#{WidgetList::List.get_database.final_results['NAME'][i]}"
     }
=end
    #
    # Alternatively you could
=begin
        WidgetList::List.get_database.final_results['ID'].each_with_index { |id,k|
          name = WidgetList::List.get_database.final_results['NAME'][k]
          price = WidgetList::List.get_database.final_results['PRICE'][k]
        }
=end

    def _exec
      if block_given?
        WidgetList::List.get_database.final_count.times {|i|
          yield i
        }
      end
    end

    def _determine_type(sql_or_obj)
      if sql_or_obj.class.name.downcase != 'string' && sql_or_obj.class.name.to_s.split('::').last.downcase  == 'dataset'
        sql = sql_or_obj.get_sql()
      elsif sql_or_obj.class.name.downcase == 'string'
        sql = sql_or_obj
      end
    end

    # probably not needed really
    def _update(sql_or_obj,bind={})

    end

    # @param [Object] replace_in_query
    def _bind(sql='',replace_in_query={})
      if !replace_in_query.empty? && replace_in_query.class.name == 'Hash'
        tmp = {}
        replace_in_query.each { |k, v|
          new_key = ':' + k.to_s
          tmp[ new_key ] = v
        }
        sql = WidgetList::Utils::fill(tmp, sql)
      end
      sql
    end

    # @param [Object or String] sql_or_obj
    #                           will either take raw SQL or a Sequel object
    # @param [Array]            bind
    #                           will be replacements for ? ? in your query.  Must be in sequence
    # @param [Hash]             replace_in_query
    #                           will be a traditional php bind hash {'BIND'=>'value'}.  which will replace :BIND in the query.  thanks mwild

    def _select(sql_or_obj, bind=[], replace_in_query={})
      # supporting either
      # if WidgetList::List.get_database._select('select * from items where name = ? AND price > ?', ['abc', 37]) > 0
      # or
      # if WidgetList::List.get_database._select(WidgetList::List.get_database[:items].filter(:name => 'abc')) > 0
      #
      sql = ''
      sql = _determine_type(sql_or_obj)

      # build csv of bind to eval below (arguments need to be like this for raw SQL passed with bind in Sequel)
      #
      parameters = _convert_bind(bind)

      # escape anything incoming in raw SQL such as bound items to create the ruby string to pass
      #
      sql.gsub!(/'/,"\\\\'")

      sql = _bind(sql,replace_in_query)

      # build rows array['COLUMN'][0] = 1234;
      #
      first   = 1
      cnt     = 0
      WidgetList::List.get_database.final_results = {}

      Rails.logger.info(sql)

      eval("
      begin
        WidgetList::List.get_database.errors = false
        WidgetList::List.get_database['" + sql + "' " +  parameters + "].each { |row|
          cnt += 1
          row.each { |k,v|
            if first == 1
              WidgetList::List.get_database.final_results[k.to_s.upcase] = []
            end
            WidgetList::List.get_database.final_results[k.to_s.upcase] << v
          }
          first = 0
        }
        WidgetList::List.get_database.last_sql = WidgetList::List.get_database['" + sql + "' " +  parameters + "].get_sql
      rescue Exception => e
        Rails.logger.info(e)
        WidgetList::List.get_database.errors = true
        WidgetList::List.get_database.last_error = e.to_s
        WidgetList::List.get_database.last_sql = '" + sql + "' + \"\n\n\n\" + ' With Bind => ' + bind.inspect + ' And  BindLegacy => ' + replace_in_query.inspect
      end
      ")
      WidgetList::List.get_database.final_count = cnt
      return cnt
    end
  end

  class Dataset
    def get_sql
      select_sql()
    end
  end
end