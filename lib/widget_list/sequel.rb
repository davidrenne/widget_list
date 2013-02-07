module Sequel
  class Database
    @final_results = {}
    attr_accessor :final_results

    @errors = false
    attr_accessor :errors

    @last_error = ''
    attr_accessor :last_error

    @db_type = ''
    attr_accessor :db_type

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

    def _convert_active_record_bind(sql='',bind=[])
      unless bind.empty?
        (bind||{}).each { |v|
          sql.sub!(/\?/,v.to_s)
        }
      end
    end

    # _exec, pass a block and iterate the total rows
    #
    # example
    #
=begin
     $DATABASE._exec {|i|
       asdf  = "#{@final_results['NAME'][i]}"
     }
=end
    #
    # Alternatively you could
=begin
        @final_results['ID'].each_with_index { |id,k|
          name = @final_results['NAME'][k]
          price = @final_results['PRICE'][k]
        }
=end

    def _exec
      if block_given?
        @final_count.times {|i|
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

    def _select(sql_or_obj, bind=[], replace_in_query={}, active_record_model=false)
      # supporting either
      # if get_database._select('select * from items where name = ? AND price > ?', ['abc', 37]) > 0
      # or
      # if get_database._select(get_database[:items].filter(:name => 'abc')) > 0
      #
      sql = ''
      sql = _determine_type(sql_or_obj)

      if self.class.name != 'WidgetListActiveRecord'

        # build csv of bind to eval below (arguments need to be like this for raw SQL passed with bind in Sequel)
        #
        parameters = _convert_bind(bind)

        # escape anything incoming in raw SQL such as bound items to create the ruby string to pass
        #
        sql.gsub!(/'/,"\\\\'")
      else

        _convert_active_record_bind(sql, bind)

      end

      sql = _bind(sql,replace_in_query)

      # build rows array['COLUMN'][0] = 1234;
      #
      first   = 1
      cnt     = 0
      @final_results = {}

      Rails.logger.info(sql)

      if self.class.name == 'WidgetListActiveRecord'
        begin
          results = active_record_model.find_by_sql(sql)
          (results||[]).each { |row|
            cnt += 1
            row.attributes.keys.each { |fieldName|
              if first == 1
                @final_results[fieldName.to_s.upcase] = []
              end
              @final_results[fieldName.to_s.upcase] << row.send(fieldName)
            }
            first = 0
          }
          @last_sql = sql_or_obj

        rescue Exception => e
          Rails.logger.info(e)
          @errors = true
          @last_error = e.to_s
          @last_sql = sql_or_obj
        end
      else
        eval("
          begin
            @errors = false
            self['" + sql + "' " +  parameters + "].each { |row|
              cnt += 1
              row.each { |k,v|
                if first == 1
                  @final_results[k.to_s.upcase] = []
                end
                @final_results[k.to_s.upcase] << v
              }
              first = 0
            }
            @last_sql = self['" + sql + "' " +  parameters + "].get_sql
          rescue Exception => e
            Rails.logger.info(e)
            @errors = true
            @last_error = e.to_s
            @last_sql = '" + sql + "' + \"\n\n\n\" + ' With Bind => ' + bind.inspect + ' And  BindLegacy => ' + replace_in_query.inspect
          end
        ")
      end
      @final_count = cnt
      return cnt
    end
  end

  class Dataset
    def get_sql
      select_sql()
    end
  end
end


class WidgetListActiveRecord < Sequel::Database
  @final_results = {}
  attr_accessor :final_results

  @errors = false
  attr_accessor :errors

  @last_error = ''
  attr_accessor :last_error

  @db_type = ''
  attr_accessor :db_type

  @final_count = 0
  attr_accessor :final_count

  @last_sql = ''
  attr_accessor :last_sql

  def initialize
    asdf = 1
  end
end