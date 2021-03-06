module Hobo
  module Rapid
    module Helper

      def comma_split(x)
        case x
        when nil
          []
        when String
          x.strip.split(/\s*,\s*/)
        else
          x.compact.map{|e| comma_split(e)}.flatten
        end
      end

      def rapid_build_callbacks(options)
        callbacks = {}
        options.each do |callback, code|
          if AJAX_CALLBACKS.include?(callback.to_sym)
            name = 'on' + callback.to_s.capitalize
            callbacks[name] = "function(request){#{code}}"
          end
        end
        callbacks
      end


      def options_for_hobo_ajax(options)
        js_options = rapid_build_callbacks(options)

        js_options['asynchronous']  = false if options[:type] == :synchronous
        js_options['method']        = method_option_to_s(options[:method]) if options[:method]
        js_options['evalScripts']   = false if options[:script] == false
        js_options['form']          = options[:form] if options[:form]
        js_options['params']        = make_params_js(options[:params]) if options[:params]
        js_options['resultUpdate']  = js_result_updates(options[:result_update]) if options[:result_update]
        js_options['resetForm']     = options[:reset_form] if options.has_key?(:reset_form)
        js_options['refocusForm']   = options[:refocus_form] if options.has_key?(:refocus_form)
        js_options['spinnerNextTo'] = js_str(options[:spinner_next_to]) if options.has_key?(:spinner_next_to)
        js_options['message']       = js_str(options[:message]) if options[:message]

        js_options.empty? ? nil : options_for_javascript(js_options)
      end


      def js_updates(updates)
        return '[]' unless updates
        updates = [updates] unless updates.is_a? Array
        updates = comma_split(updates).map do |u|
          if u.to_s == "self"
            "Hobo.partFor(this)"
          else
            js_str(u)
          end
        end
        "[#{updates * ', '}]"
      end


      def js_result_updates(updates)
        return '[]' unless updates
        updates = [updates] unless updates.is_a? Array
        pairs = comma_split(updates).map &it.split(/\s*=\s*/)
        '[' + pairs.map{|p| "{id: #{js_str(p[0])}, result: #{js_str(p[1])}}"}.join(", ") + ']'
      end


      def ajax_updater(url_or_form, update, options={})
        options ||= {}
        options = options.symbolize_keys

        target = if url_or_form == :post_form
                   target = "this"
                 else
                   js_str(url_or_form)
                 end
        js_options = options_for_hobo_ajax(options)
        args = [target, js_updates(update), js_options].compact

        confirm = options.delete(:confirm)

        func = "Hobo.ajaxRequest(#{args * ', '})"
        if confirm
          "if (confirm(#{js_str(confirm)})) { #{func} }"
        else
          func
        end
      end


      def a_or_an(word)
        if word =~ /^[aeiouh]/
          "an #{word}"
        else
          "a #{word}"
        end
      end


      def no_break(s)
        s = new_context { yield } if block_given?
        s.gsub(' ', '&nbsp;')
      end

      # returns the number of items in the collection.  See LH #889
      def collection_count
        this.try.to_int || this.try.total_entries || (this.try.loaded? && this.try.length) || this.try.count || this.try.length
      end


      def in_place_editor(attributes, this=nil)
        blank_message = attributes.delete(:blank_message) ||
                        t('hobo.in_place_editor.click_to_edit', :default => '(click to edit)')

        attributes = add_classes(attributes, "in-place-edit", model_id_class(this_parent, this_field))
        attributes.update(:hobo_blank_message => blank_message,
                          :if_blank => blank_message,
                          :no_wrapper => false)

        edit_text = this._?.to_s
        attributes.update(:hobo_edit_text => edit_text) unless edit_text.nil?

        if update = attributes.delete(:update)
          attributes = add_classes(attributes, update_elements_class(update))
        end

        view(attributes)
      end



      AJAX_CALLBACKS = [ :success, :failure, :complete, :before ]

      AJAX_UPDATE_ATTRS = [  :update, :updates, :ajax ]

      AJAX_EFFECT_ATTRS = [ :hide, :show ]

      AJAX_SPINNER_ATTRS = [:spinner_next_to, :spinner_options, :spinner_at, :no_spinner, :message]

      AJAX_PUSHSTATE_ATTRS = [:push_state, :new_title]

      AJAX_ATTRS = AJAX_CALLBACKS + AJAX_UPDATE_ATTRS + AJAX_EFFECT_ATTRS + AJAX_SPINNER_ATTRS + AJAX_PUSHSTATE_ATTRS
        [
         :type, :method, :script, :form, :result_update, # FIXME: these 5 are not required/used by hobo-jquery: delete when prototype.js support is dropped
         :params, :confirm, :errors_ok,
         :reset_form, :refocus_form ]

      def through_collection_names(object=this)
        object.class.reflections.values.select do |refl|
          refl.macro == :has_many && refl.options[:through]
        end.map {|x| x.options[:through]}
      end


      def non_through_collections(object=this)
        names = object.class.reflections.values.select do |refl|
          refl.macro == :has_many
        end.*.name

        names - through_collection_names
      end

      def standard_fields(model, include_timestamps=false)
        fields = model.attr_order.*.to_s & model.content_columns.*.name
        fields -= %w{created_at updated_at created_on updated_on deleted_at} unless include_timestamps
        fields.reject! { |f| model.never_show? f }
        fields
      end

      def current_time
        Time.zone ? Time.zone.now : Time.now
      end

    end
  end
end
