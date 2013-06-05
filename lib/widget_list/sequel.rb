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

    def _get_row_value(row,fieldName)
      row.send(fieldName).to_s
    end

    # @param [Object or String] sql_or_obj
    #                           will either take raw SQL or a Sequel object
    # @param [Array]            bind
    #                           will be replacements for ? ? in your query.  Must be in sequence
    # @param [Hash]             replace_in_query
    #                           will be a traditional php bind hash {'BIND'=>'value'}.  which will replace :BIND in the query.  thanks mwild

    def _select(sql_or_obj, bind=[], replace_in_query={}, active_record_model=false, group_match=false)
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
      tmp     = nil
      @final_results = {}
      if Rails.env == 'development'
        Rails.logger.info(sql)
      end

      if self.class.name == 'WidgetListActiveRecord'
        begin

          if $is_mongo
            if !group_match.nil?
              params = []

              if group_match.key?('match') && !group_match['match'].empty?
                group_match['match'].each { |match|
                  field = match.keys.first
                  if active_record_model.respond_to?(:serializers) &&  active_record_model.serializers[field].type.to_s == 'Integer'
                    if match[match.keys.first].class.name == 'Hash'
                      predicate      = match[field].keys.first
                      value_original = match[field][predicate]
                      match_final = {
                          field => { predicate =>
                                         WidgetList::List.parse_inputs_for_mongo_predicates(active_record_model, field, predicate, value_original)
                          }
                      }
                    else
                      match_final = { field => WidgetList::List.parse_inputs_for_mongo_predicates(active_record_model, field, predicate, value_original) }
                    end

                  else
                    match_final = { field => WidgetList::List.parse_inputs_for_mongo_predicates(active_record_model, field, predicate, value_original) }
                  end
                  params << {
                      '$match' =>  match_final
                  }
                }
              end

              params << group_match['group'] if group_match.key?('group')
              params << group_match['sort']  if group_match.key?('sort')
              params << group_match['skip']  if group_match.key?('skip')
              params << group_match['limit'] if group_match.key?('limit')

              active_record_model = active_record_model.collection.aggregate(params)
            end
          end

          if $is_mongo && sql == 'count'

            cnt = active_record_model.count
            @final_results['TOTAL'] = []
            @final_results['TOTAL'][0] = cnt

          else

            if $is_mongo
              if !tmp.nil?
                results = tmp
              else
                results = active_record_model.all.to_a if active_record_model.respond_to?('all')
                results = active_record_model.to_a if active_record_model.respond_to?('to_a') && !group_match.nil?
              end
            else
              results = active_record_model.find_by_sql(sql)
            end

            (results||[]).each { |row|
              cnt += 1
              row.attributes.keys.each { |fieldName|
                if first == 1
                  @final_results[fieldName.to_s.upcase] = []
                end
                @final_results[fieldName.to_s.upcase] << ((row.send(fieldName).nil? && row.attributes[fieldName].nil?) ? '' : _get_row_value(row,fieldName))
              } if group_match.nil?

              row.each { |key,value|
                if first == 1
                  @final_results['CNT'] = []
                  if key == '_id'
                    value.each { |k,v|
                      @final_results[k.to_s.upcase] = []
                    }
                  end
                end
                if key == 'cnt'
                  @final_results['CNT'] << value
                elsif key == '_id'
                  value.each { |k,v|
                    @final_results[k.to_s.upcase] << v
                  }
                end

              } if !group_match.nil?

              first = 0
            }
            @last_sql = sql_or_obj
          end

        rescue Exception => e
          cnt         = 0
          Rails.logger.info(e)
          @errors     = true
          @last_error = e.to_s
          @last_sql   = sql_or_obj
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
end