Watch =
	prepareWatch: (model,callback) ->
		bind = (record, prop, handler) ->
			record["_"+prop] = record[prop] if record[prop]? and record.hasOwnProperty(prop)

			getter = ->
				return record["_"+prop]

			setter = (value) ->
				return if record["_"+prop] is value
				return if not record["_"+prop] and value is ""
				# Adding a special case to NOT short-circuit on arrays below. 
				# The entire line probably needs to go. Nobody knows why it's there, and it breaks the case where you do
				# someWatchedObject.someArrayProperty = [1, 2, 3]
				# Nothing gets assigned in that case (without the special handling for arrays), and that's wrong.
				# It's probably wrong for objects, as well, but don't want to remove this with only days until production.
				return if (not Spine.isArray(record["_"+prop])) and record["_"+prop] and value and typeof record["_"+prop] is 'object' and typeof value is 'object' and Object.getPrototypeOf(record["_"+prop]) is Object.getPrototypeOf(value)
				previous = record["_"+prop]
				record["_"+prop] = value
				console.log("Spine.Watch: Updating #{prop} from '#{previous}' to '#{record["_"+prop]}'") if window.DebugLevel >= 8
				handler.call(record, prop, record["_"+prop], value)

			if delete record[prop]
				if Object.defineProperty
					Object.defineProperty(record, prop,  
						get: getter,
						set: setter,
						enumerable: true,
						configurable: true
					)
				else if Object.prototype.__defineGetter__ and 
						Object.prototype.__defineSetter__
					Object.prototype.__defineGetter__.call(record, prop, getter)
					Object.prototype.__defineSetter__.call(record, prop, setter)

		unbind = (record, prop) ->
			value = record[prop]
			delete this[prop]
			record[prop] = value

		trigger = (prop,previous,current) ->
			if callback
				callback("update[]", current, prop, previous)
				callback("update[#{prop}]", current, prop, previous)
			else
				@trigger("update[]", current, prop, previous)
				@trigger("update[#{prop}]", current, prop, previous)

		if model
			bind(model, attribute, trigger) for attribute of model
		else
			bind(@, attribute, trigger) for attribute in @constructor.attributes

			@bind("destroy", -> 
				unbind(@, attribute) for attribute in @constructor.attributes
			)

		@watchEnabled = true
		
		@

Watch.activators = [ "prepareWatch" ] if Spine.Activator

@Spine.Watch = Watch

# Duck punching Spine's clone method so we can add another watch layer
@Spine.Model::clone = ->
	o = Object.create(@)
	if o.prepareWatch
		o.prepareWatch();
	return o