# ##############################################################################
#(G)odot (U)nit (T)est class
#
# ##############################################################################
# The MIT License (MIT)
# =====================
#
# Copyright (c) 2020 Tom "Butch" Wesley
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# ##############################################################################
# View readme for usage details.
#
# Version - see gut.gd
# ##############################################################################
# Class that all test scripts must extend.
#
# This provides all the asserts and other testing features.  Test scripts are
# run by the Gut class in gut.gd
# ##############################################################################
extends Node

# ------------------------------------------------------------------------------
# Helper class to hold info for objects to double.  This extracts info and has
# some convenience methods.  This is key in being able to make the "smart double"
# method which makes doubling much easier for the user.
# ------------------------------------------------------------------------------
class DoubleInfo:
	var path
	var subpath
	var strategy
	var make_partial
	var extension
	var _utils = load('res://addons/gut/utils.gd').get_instance()
	var _is_native = false
	var is_valid = false

	# Flexible init method.  p2 can be subpath or stategy unless p3 is
	# specified, then p2 must be subpath and p3 is strategy.
	#
	# Examples:
	#   (object_to_double)
	#   (object_to_double, subpath)
	#   (object_to_double, strategy)
	#   (object_to_double, subpath, strategy)
	func _init(thing, p2=null, p3=null):
		strategy = p2

		# short-circuit and ensure that is_valid
		# is not set to true.
		if(_utils.is_instance(thing)):
			return

		if(typeof(p2) == TYPE_STRING):
			strategy = p3
			subpath = p2

		if(typeof(thing) == TYPE_OBJECT):
			if(_utils.is_native_class(thing)):
				path = thing
				_is_native = true
				extension = 'native_class_not_used'
			else:
				path = thing.resource_path
		else:
			path = thing

		if(!_is_native):
			extension = path.get_extension()

		is_valid = true

	func is_scene():
		return extension == 'tscn'

	func is_script():
		return extension == 'gd'

	func is_native():
		return _is_native

# ------------------------------------------------------------------------------
# Begin test.gd
# ------------------------------------------------------------------------------
var _utils = load('res://addons/gut/utils.gd').get_instance()
var _compare = _utils.Comparator.new()

# constant for signal when calling yield_for
const YIELD = 'timeout'

# Need a reference to the instance that is running the tests.  This
# is set by the gut class when it runs the tests.  This gets you
# access to the asserts in the tests you write.
var gut = null

var _disable_strict_datatype_checks = false
# Holds all the text for a test's fail/pass.  This is used for testing purposes
# to see the text of a failed sub-test in test_test.gd
var _fail_pass_text = []

const EDITOR_PROPERTY = PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT
const VARIABLE_PROPERTY = PROPERTY_USAGE_SCRIPT_VARIABLE

# Used with assert_setget
enum {
	DEFAULT_SETTER_GETTER,
	SETTER_ONLY,
	GETTER_ONLY
}

# Summary counts for the test.
var _summary = {
	asserts = 0,
	passed = 0,
	failed = 0,
	tests = 0,
	pending = 0
}

# This is used to watch signals so we can make assertions about them.
var _signal_watcher = load('res://addons/gut/signal_watcher.gd').new()

# Convenience copy of _utils.DOUBLE_STRATEGY
var DOUBLE_STRATEGY = null
var _lgr = _utils.get_logger()
var _strutils = _utils.Strutils.new()

# syntax sugar
var ParameterFactory = _utils.ParameterFactory
var CompareResult = _utils.CompareResult

func _init():
	DOUBLE_STRATEGY = _utils.DOUBLE_STRATEGY # yes, this is right

func _str(thing):
	return _strutils.type2str(thing)

# ------------------------------------------------------------------------------
# Fail an assertion.  Causes test and script to fail as well.
# ------------------------------------------------------------------------------
func _fail(text):
	_summary.asserts += 1
	_summary.failed += 1
	_fail_pass_text.append('failed:  ' + text)
	if(gut):
		_lgr.failed(text)
		gut._fail(text)

# ------------------------------------------------------------------------------
# Pass an assertion.
# ------------------------------------------------------------------------------
func _pass(text):
	_summary.asserts += 1
	_summary.passed += 1
	_fail_pass_text.append('passed:  ' + text)
	if(gut):
		_lgr.passed(text)
		gut._pass(text)

# ------------------------------------------------------------------------------
# Checks if the datatypes passed in match.  If they do not then this will cause
# a fail to occur.  If they match then TRUE is returned, FALSE if not.  This is
# used in all the assertions that compare values.
# ------------------------------------------------------------------------------
func _do_datatypes_match__fail_if_not(got, expected, text):
	var did_pass = true

	if(!_disable_strict_datatype_checks):
		var got_type = typeof(got)
		var expect_type = typeof(expected)
		if(got_type != expect_type and got != null and expected != null):
			# If we have a mismatch between float and int (types 2 and 3) then
			# print out a warning but do not fail.
			if([2, 3].has(got_type) and [2, 3].has(expect_type)):
				_lgr.warn(str('Warn:  Float/Int comparison.  Got ', _strutils.types[got_type],
					' but expected ', _strutils.types[expect_type]))
			else:
				_fail('Cannot compare ' + _strutils.types[got_type] + '[' + _str(got) + '] to ' + \
					_strutils.types[expect_type] + '[' + _str(expected) + '].  ' + text)
				did_pass = false

	return did_pass

# ------------------------------------------------------------------------------
# Create a string that lists all the methods that were called on an spied
# instance.
# ------------------------------------------------------------------------------
func _get_desc_of_calls_to_instance(inst):
	var BULLET = '  * '
	var calls = gut.get_spy().get_call_list_as_string(inst)
	# indent all the calls
	calls = BULLET + calls.replace("\n", "\n" + BULLET)
	# remove trailing newline and bullet
	calls = calls.substr(0, calls.length() - BULLET.length() - 1)
	return "Calls made on " + str(inst) + "\n" + calls

# ------------------------------------------------------------------------------
# Signal assertion helper.  Do not call directly, use _can_make_signal_assertions
# ------------------------------------------------------------------------------
func _fail_if_does_not_have_signal(object, signal_name):
	var did_fail = false
	if(!_signal_watcher.does_object_have_signal(object, signal_name)):
		_fail(str('Object ', object, ' does not have the signal [', signal_name, ']'))
		did_fail = true
	return did_fail

# ------------------------------------------------------------------------------
# Signal assertion helper.  Do not call directly, use _can_make_signal_assertions
# ------------------------------------------------------------------------------
func _fail_if_not_watching(object):
	var did_fail = false
	if(!_signal_watcher.is_watching_object(object)):
		_fail(str('Cannot make signal assertions because the object ', object, \
				  ' is not being watched.  Call watch_signals(some_object) to be able to make assertions about signals.'))
		did_fail = true
	return did_fail

# ------------------------------------------------------------------------------
# Returns text that contains original text and a list of all the signals that
# were emitted for the passed in object.
# ------------------------------------------------------------------------------
func _get_fail_msg_including_emitted_signals(text, object):
	return str(text," (Signals emitted: ", _signal_watcher.get_signals_emitted(object), ")")

# ------------------------------------------------------------------------------
# This validates that parameters is an array and generates a specific error
# and a failure with a specific message
# ------------------------------------------------------------------------------
func _fail_if_parameters_not_array(parameters):
	var invalid = parameters != null and typeof(parameters) != TYPE_ARRAY
	if(invalid):
		_lgr.error('The "parameters" parameter must be an array of expected parameter values.')
		_fail('Cannot compare paramter values because an array was not passed.')
	return invalid


func _create_obj_from_type(type):
	var obj = null
	if type.is_class("PackedScene"):
		obj = type.instantiate()
		add_child(obj)
	else:
		obj = type.new()
	return obj


func _get_type_from_obj(obj):
	var type = null
	if obj.has_method(get_scene_file_path()):
			type = load(obj.get_scene_file_path())
	else:
			type = obj.get_script()
	return type

# #######################
# Virtual Methods
# #######################

# alias for prerun_setup
func before_all():
	pass

# alias for setup
func before_each():
	pass

# alias for postrun_teardown
func after_all():
	pass

# alias for teardown
func after_each():
	pass

# #######################
# Public
# #######################

func get_logger():
	return _lgr

func set_logger(logger):
	_lgr = logger


# #######################
# Asserts
# #######################

# ------------------------------------------------------------------------------
# Asserts that the expected value equals the value got.
# ------------------------------------------------------------------------------
func assert_eq(got, expected, text=""):

	if(_do_datatypes_match__fail_if_not(got, expected, text)):
		var disp = "[" + _str(got) + "] expected to equal [" + _str(expected) + "]:  " + text
		var result = null

		if(typeof(got) == TYPE_ARRAY):
			result = _compare.shallow(got, expected)
		else:
			result = _compare.simple(got, expected)

		if(typeof(got) in [TYPE_ARRAY, TYPE_DICTIONARY]):
			disp = str(result.summary, '  ', text)

		if(result.are_equal):
			_pass(disp)
		else:
			_fail(disp)


# ------------------------------------------------------------------------------
# Asserts that the value got does not equal the "not expected" value.
# ------------------------------------------------------------------------------
func assert_ne(got, not_expected, text=""):
	if(_do_datatypes_match__fail_if_not(got, not_expected, text)):
		var disp = "[" + _str(got) + "] expected to not equal [" + _str(not_expected) + "]:  " + text
		var result = null

		if(typeof(got) == TYPE_ARRAY):
			result = _compare.shallow(got, not_expected)
		else:
			result = _compare.simple(got, not_expected)

		if(typeof(got) in [TYPE_ARRAY, TYPE_DICTIONARY]):
			disp = str(result.summary, '  ', text)

		if(result.are_equal):
			_fail(disp)
		else:
			_pass(disp)


# ------------------------------------------------------------------------------
# Asserts that the expected value almost equals the value got.
# ------------------------------------------------------------------------------
func assert_almost_eq(got, expected, error_interval, text=''):
	var disp = "[" + _str(got) + "] expected to equal [" + _str(expected) + "] +/- [" + str(error_interval) + "]:  " + text
	if(_do_datatypes_match__fail_if_not(got, expected, text) and _do_datatypes_match__fail_if_not(got, error_interval, text)):
		if(got < (expected - error_interval) or got > (expected + error_interval)):
			_fail(disp)
		else:
			_pass(disp)

# ------------------------------------------------------------------------------
# Asserts that the expected value does not almost equal the value got.
# ------------------------------------------------------------------------------
func assert_almost_ne(got, not_expected, error_interval, text=''):
	var disp = "[" + _str(got) + "] expected to not equal [" + _str(not_expected) + "] +/- [" + str(error_interval) + "]:  " + text
	if(_do_datatypes_match__fail_if_not(got, not_expected, text) and _do_datatypes_match__fail_if_not(got, error_interval, text)):
		if(got < (not_expected - error_interval) or got > (not_expected + error_interval)):
			_pass(disp)
		else:
			_fail(disp)

# ------------------------------------------------------------------------------
# Asserts got is greater than expected
# ------------------------------------------------------------------------------
func assert_gt(got, expected, text=""):
	var disp = "[" + _str(got) + "] expected to be > than [" + _str(expected) + "]:  " + text
	if(_do_datatypes_match__fail_if_not(got, expected, text)):
		if(got > expected):
			_pass(disp)
		else:
			_fail(disp)

# ------------------------------------------------------------------------------
# Asserts got is less than expected
# ------------------------------------------------------------------------------
func assert_lt(got, expected, text=""):
	var disp = "[" + _str(got) + "] expected to be < than [" + _str(expected) + "]:  " + text
	if(_do_datatypes_match__fail_if_not(got, expected, text)):
		if(got < expected):
			_pass(disp)
		else:
			_fail(disp)

# ------------------------------------------------------------------------------
# asserts that got is true
# ------------------------------------------------------------------------------
func assert_true(got, text=""):
	if(typeof(got) == TYPE_BOOL):
		if(got):
			_pass(text)
		else:
			_fail(text)
	else:
		var msg = str("Cannot convert ", _strutils.type2str(got), " to boolean")
		_fail(msg)

# ------------------------------------------------------------------------------
# Asserts that got is false
# ------------------------------------------------------------------------------
func assert_false(got, text=""):
	if(typeof(got) == TYPE_BOOL):
		if(got):
			_fail(text)
		else:
			_pass(text)
	else:
		var msg = str("Cannot convert ", _strutils.type2str(got), " to boolean")
		_fail(msg)

# ------------------------------------------------------------------------------
# Asserts value is between (inclusive) the two expected values.
# ------------------------------------------------------------------------------
func assert_between(got, expect_low, expect_high, text=""):
	var disp = "[" + _str(got) + "] expected to be between [" + _str(expect_low) + "] and [" + str(expect_high) + "]:  " + text

	if(_do_datatypes_match__fail_if_not(got, expect_low, text) and _do_datatypes_match__fail_if_not(got, expect_high, text)):
		if(expect_low > expect_high):
			disp = "INVALID range.  [" + str(expect_low) + "] is not less than [" + str(expect_high) + "]"
			_fail(disp)
		else:
			if(got < expect_low or got > expect_high):
				_fail(disp)
			else:
				_pass(disp)

# ------------------------------------------------------------------------------
# Asserts value is not between (exclusive) the two expected values.
# ------------------------------------------------------------------------------
func assert_not_between(got, expect_low, expect_high, text=""):
	var disp = "[" + _str(got) + "] expected not to be between [" + _str(expect_low) + "] and [" + str(expect_high) + "]:  " + text

	if(_do_datatypes_match__fail_if_not(got, expect_low, text) and _do_datatypes_match__fail_if_not(got, expect_high, text)):
		if(expect_low > expect_high):
			disp = "INVALID range.  [" + str(expect_low) + "] is not less than [" + str(expect_high) + "]"
			_fail(disp)
		else:
			if(got > expect_low and got < expect_high):
				_fail(disp)
			else:
				_pass(disp)

# ------------------------------------------------------------------------------
# Uses the 'has' method of the object passed in to determine if it contains
# the passed in element.
# ------------------------------------------------------------------------------
func assert_has(obj, element, text=""):
	var disp = str('Expected [', _str(obj), '] to contain value:  [', _str(element), ']:  ', text)
	if(obj.has(element)):
		_pass(disp)
	else:
		_fail(disp)

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
func assert_does_not_have(obj, element, text=""):
	var disp = str('Expected [', _str(obj), '] to NOT contain value:  [', _str(element), ']:  ', text)
	if(obj.has(element)):
		_fail(disp)
	else:
		_pass(disp)

# ------------------------------------------------------------------------------
# Asserts that a file exists
# ------------------------------------------------------------------------------
func assert_file_exists(file_path):
	var disp = 'expected [' + file_path + '] to exist.'
	var f = File.new()
	if(f.file_exists(file_path)):
		_pass(disp)
	else:
		_fail(disp)

# ------------------------------------------------------------------------------
# Asserts that a file should not exist
# ------------------------------------------------------------------------------
func assert_file_does_not_exist(file_path):
	var disp = 'expected [' + file_path + '] to NOT exist'
	var f = File.new()
	if(!f.file_exists(file_path)):
		_pass(disp)
	else:
		_fail(disp)

# ------------------------------------------------------------------------------
# Asserts the specified file is empty
# ------------------------------------------------------------------------------
func assert_file_empty(file_path):
	var disp = 'expected [' + file_path + '] to be empty'
	var f = File.new()
	if(f.file_exists(file_path) and gut.is_file_empty(file_path)):
		_pass(disp)
	else:
		_fail(disp)

# ------------------------------------------------------------------------------
# Asserts the specified file is not empty
# ------------------------------------------------------------------------------
func assert_file_not_empty(file_path):
	var disp = 'expected [' + file_path + '] to contain data'
	if(!gut.is_file_empty(file_path)):
		_pass(disp)
	else:
		_fail(disp)

# ------------------------------------------------------------------------------
# Asserts the object has the specified method
# ------------------------------------------------------------------------------
func assert_has_method(obj, method):
	assert_true(obj.has_method(method), _str(obj) + ' should have method: ' + method)

# Old deprecated method name
func assert_get_set_methods(obj, property, default, set_to):
	_lgr.deprecated('assert_get_set_methods', 'assert_accessors')
	assert_accessors(obj, property, default, set_to)

# ------------------------------------------------------------------------------
# Verifies the object has get and set methods for the property passed in.  The
# property isn't tied to anything, just a name to be appended to the end of
# get_ and set_.  Asserts the get_ and set_ methods exist, if not, it stops there.
# If they exist then it asserts get_ returns the expected default then calls
# set_ and asserts get_ has the value it was set to.
# ------------------------------------------------------------------------------
func assert_accessors(obj, property, default, set_to):
	var fail_count = _summary.failed
	var get = 'get_' + property
	var set = 'set_' + property
	assert_has_method(obj, get)
	assert_has_method(obj, set)
	# SHORT CIRCUIT
	if(_summary.failed > fail_count):
		return
	assert_eq(obj.call(get), default, 'It should have the expected default value.')
	obj.call(set, set_to)
	assert_eq(obj.call(get), set_to, 'The set value should have been returned.')


# ---------------------------------------------------------------------------
# Property search helper.  Used to retrieve Dictionary of specified property
# from passed object. Returns null if not found.
# If provided, property_usage constrains the type of property returned by
# passing either:
# EDITOR_PROPERTY for properties defined as: export(int) var some_value
# VARIABLE_PROPERTY for properties defined as: var another_value
# ---------------------------------------------------------------------------
func _find_object_property(obj, property_name, property_usage=null):
	var result = null
	var found = false
	var properties = obj.get_property_list()

	while !found and !properties.is_empty():
		var property = properties.pop_back()
		if property['name'] == property_name:
			if property_usage == null or property['usage'] == property_usage:
				result = property
				found = true
	return result

# ------------------------------------------------------------------------------
# Asserts a class exports a variable.
# ------------------------------------------------------------------------------
func assert_exports(obj, property_name, type):
	var disp = 'expected %s to have editor property [%s]' % [_str(obj), property_name]
	var property = _find_object_property(obj, property_name, EDITOR_PROPERTY)
	if property != null:
		disp += ' of type [%s]. Got type [%s].' % [_strutils.types[type], _strutils.types[property['type']]]
		if property['type'] == type:
			_pass(disp)
		else:
			_fail(disp)
	else:
		_fail(disp)

# ------------------------------------------------------------------------------
# Signal assertion helper.
#
# Verifies that the object and signal are valid for making signal assertions.
# This will fail with specific messages that indicate why they are not valid.
# This returns true/false to indicate if the object and signal are valid.
# ------------------------------------------------------------------------------
func _can_make_signal_assertions(object, signal_name):
	return !(_fail_if_not_watching(object) or _fail_if_does_not_have_signal(object, signal_name))

# ------------------------------------------------------------------------------
# Check if an object is connected to a signal on another object. Returns True
# if it is and false otherwise
# ------------------------------------------------------------------------------
func _is_connected(signaler_obj, connect_to_obj, signal_name, method_name=""):
	if(method_name != ""):
		return signaler_obj.is_connected(signal_name, Callable(connect_to_obj, method_name))
	else:
		var connections = signaler_obj.get_signal_connection_list(signal_name)
		for conn in connections:
			if((conn.source == signaler_obj) and (conn.target == connect_to_obj)):
				return true
		return false
# ------------------------------------------------------------------------------
# Watch the signals for an object.  This must be called before you can make
# any assertions about the signals themselves.
# ------------------------------------------------------------------------------
func watch_signals(object):
	_signal_watcher.watch_signals(object)

# ------------------------------------------------------------------------------
# Asserts that an object is connected to a signal on another object
#
# This will fail with specific messages if the target object is not connected
# to the specified signal on the source object.
# ------------------------------------------------------------------------------
func assert_connected(signaler_obj, connect_to_obj, signal_name, method_name=""):
	pass
	var method_disp = ''
	if (method_name != ""):
		method_disp = str(' using method: [', method_name, '] ')
	var disp = str('Expected object ', _str(signaler_obj),\
		' to be connected to signal: [', signal_name, '] on ',\
		_str(connect_to_obj), method_disp)
	if(_is_connected(signaler_obj, connect_to_obj, signal_name, method_name)):
		_pass(disp)
	else:
		_fail(disp)

# ------------------------------------------------------------------------------
# Asserts that an object is not connected to a signal on another object
#
# This will fail with specific messages if the target object is connected
# to the specified signal on the source object.
# ------------------------------------------------------------------------------
func assert_not_connected(signaler_obj, connect_to_obj, signal_name, method_name=""):
	var method_disp = ''
	if (method_name != ""):
		method_disp = str(' using method: [', method_name, '] ')
	var disp = str('Expected object ', _str(signaler_obj),\
		' to not be connected to signal: [', signal_name, '] on ',\
		_str(connect_to_obj), method_disp)
	if(_is_connected(signaler_obj, connect_to_obj, signal_name, method_name)):
		_fail(disp)
	else:
		_pass(disp)

# ------------------------------------------------------------------------------
# Asserts that a signal has been emitted at least once.
#
# This will fail with specific messages if the object is not being watched or
# the object does not have the specified signal
# ------------------------------------------------------------------------------
func assert_signal_emitted(object, signal_name, text=""):
	var disp = str('Expected object ', _str(object), ' to have emitted signal [', signal_name, ']:  ', text)
	if(_can_make_signal_assertions(object, signal_name)):
		if(_signal_watcher.did_emit(object, signal_name)):
			_pass(disp)
		else:
			_fail(_get_fail_msg_including_emitted_signals(disp, object))

# ------------------------------------------------------------------------------
# Asserts that a signal has not been emitted.
#
# This will fail with specific messages if the object is not being watched or
# the object does not have the specified signal
# ------------------------------------------------------------------------------
func assert_signal_not_emitted(object, signal_name, text=""):
	var disp = str('Expected object ', _str(object), ' to NOT emit signal [', signal_name, ']:  ', text)
	if(_can_make_signal_assertions(object, signal_name)):
		if(_signal_watcher.did_emit(object, signal_name)):
			_fail(disp)
		else:
			_pass(disp)

# ------------------------------------------------------------------------------
# Asserts that a signal was fired with the specified parameters.  The expected
# parameters should be passed in as an array.  An optional index can be passed
# when a signal has fired more than once.  The default is to retrieve the most
# recent emission of the signal.
#
# This will fail with specific messages if the object is not being watched or
# the object does not have the specified signal
# ------------------------------------------------------------------------------
func assert_signal_emitted_with_parameters(object, signal_name, parameters, index=-1):
	var disp = str('Expected object ', _str(object), ' to emit signal [', signal_name, '] with parameters ', parameters, ', got ')
	if(_can_make_signal_assertions(object, signal_name)):
		if(_signal_watcher.did_emit(object, signal_name)):
			var parms_got = _signal_watcher.get_signal_parameters(object, signal_name, index)
			var diff_result = _compare.deep(parameters, parms_got)
			if(diff_result.are_equal()):
				_pass(str(disp, parms_got))
			else:
				_fail(str('Expected object ', _str(object), ' to emit signal [', signal_name, '] with parameters ', diff_result.summarize()))
		else:
			var text = str('Object ', object, ' did not emit signal [', signal_name, ']')
			_fail(_get_fail_msg_including_emitted_signals(text, object))

# ------------------------------------------------------------------------------
# Assert that a signal has been emitted a specific number of times.
#
# This will fail with specific messages if the object is not being watched or
# the object does not have the specified signal
# ------------------------------------------------------------------------------
func assert_signal_emit_count(object, signal_name, times, text=""):

	if(_can_make_signal_assertions(object, signal_name)):
		var count = _signal_watcher.get_emit_count(object, signal_name)
		var disp = str('Expected the signal [', signal_name, '] emit count of [', count, '] to equal [', times, ']: ', text)
		if(count== times):
			_pass(disp)
		else:
			_fail(_get_fail_msg_including_emitted_signals(disp, object))

# ------------------------------------------------------------------------------
# Assert that the passed in object has the specified signal
# ------------------------------------------------------------------------------
func assert_has_signal(object, signal_name, text=""):
	var disp = str('Expected object ', _str(object), ' to have signal [', signal_name, ']:  ', text)
	if(_signal_watcher.does_object_have_signal(object, signal_name)):
		_pass(disp)
	else:
		_fail(disp)

# ------------------------------------------------------------------------------
# Returns the number of times a signal was emitted.  -1 returned if the object
# is not being watched.
# ------------------------------------------------------------------------------
func get_signal_emit_count(object, signal_name):
	return _signal_watcher.get_emit_count(object, signal_name)

# ------------------------------------------------------------------------------
# Get the parmaters of a fired signal.  If the signal was not fired null is
# returned.  You can specify an optional index (use get_signal_emit_count to
# determine the number of times it was emitted).  The default index is the
# latest time the signal was fired (size() -1 insetead of 0).  The parameters
# returned are in an array.
# ------------------------------------------------------------------------------
func get_signal_parameters(object, signal_name, index=-1):
	return _signal_watcher.get_signal_parameters(object, signal_name, index)

# ------------------------------------------------------------------------------
# Get the parameters for a method call to a doubled object.  By default it will
# return the most recent call.  You can optionally specify an index.
#
# Returns:
# * an array of parameter values if a call the method was found
# * null when a call to the method was not found or the index specified was
#   invalid.
# ------------------------------------------------------------------------------
func get_call_parameters(object, method_name, index=-1):
	var to_return = null
	if(_utils.is_double(object)):
		to_return = gut.get_spy().get_call_parameters(object, method_name, index)
	else:
		_lgr.error('You must pass a doulbed object to get_call_parameters.')

	return to_return

# ------------------------------------------------------------------------------
# Assert that object is an instance of a_class
# ------------------------------------------------------------------------------
func assert_extends(object, a_class, text=''):
	_lgr.deprecated('assert_extends', 'assert_is')
	assert_is(object, a_class, text)

# Alias for assert_extends
func assert_is(object, a_class, text=''):
	var disp  = ''#var disp = str('Expected [', _str(object), '] to be type of [', a_class, ']: ', text)
	var NATIVE_CLASS = 'GDScriptNativeClass'
	var GDSCRIPT_CLASS = 'GDScript'
	var bad_param_2 = 'Parameter 2 must be a Class (like Node2D or Label).  You passed '

	if(typeof(object) != TYPE_OBJECT):
		_fail(str('Parameter 1 must be an instance of an object.  You passed:  ', _str(object)))
	elif(typeof(a_class) != TYPE_OBJECT):
		_fail(str(bad_param_2, _str(a_class)))
	else:
		var a = _str(a_class)
		disp = str('Expected [', _str(object), '] to extend [', _str(a_class), ']: ', text)
		if(a_class.get_class() != NATIVE_CLASS and a_class.get_class() != GDSCRIPT_CLASS):
			_fail(str(bad_param_2, _str(a_class)))
		else:
			if(object is a_class):
				_pass(disp)
			else:
				_fail(disp)

func _get_typeof_string(the_type):
	var to_return = ""
	if(_strutils.types.has(the_type)):
		to_return += str(the_type, '(',  _strutils.types[the_type], ')')
	else:
		to_return += str(the_type)
	return to_return

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
func assert_typeof(object, type, text=''):
	var disp = str('Expected [typeof(', object, ') = ')
	disp += _get_typeof_string(typeof(object))
	disp += '] to equal ['
	disp += _get_typeof_string(type) +  ']'
	disp += '.  ' + text
	if(typeof(object) == type):
		_pass(disp)
	else:
		_fail(disp)

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
func assert_not_typeof(object, type, text=''):
	var disp = str('Expected [typeof(', object, ') = ')
	disp += _get_typeof_string(typeof(object))
	disp += '] to not equal ['
	disp += _get_typeof_string(type) +  ']'
	disp += '.  ' + text
	if(typeof(object) != type):
		_pass(disp)
	else:
		_fail(disp)

# ------------------------------------------------------------------------------
# Assert that text contains given search string.
# The match_case flag determines case sensitivity.
# ------------------------------------------------------------------------------
func assert_string_contains(text, search, match_case=true):
	var empty_search = 'Expected text and search strings to be non-empty. You passed \'%s\' and \'%s\'.'
	var disp = 'Expected \'%s\' to contain \'%s\', match_case=%s' % [text, search, match_case]
	if(text == '' or search == ''):
		_fail(empty_search % [text, search])
	elif(match_case):
		if(text.find(search) == -1):
			_fail(disp)
		else:
			_pass(disp)
	else:
		if(text.to_lower().find(search.to_lower()) == -1):
			_fail(disp)
		else:
			_pass(disp)

# ------------------------------------------------------------------------------
# Assert that text starts with given search string.
# match_case flag determines case sensitivity.
# ------------------------------------------------------------------------------
func assert_string_starts_with(text, search, match_case=true):
	var empty_search = 'Expected text and search strings to be non-empty. You passed \'%s\' and \'%s\'.'
	var disp = 'Expected \'%s\' to start with \'%s\', match_case=%s' % [text, search, match_case]
	if(text == '' or search == ''):
		_fail(empty_search % [text, search])
	elif(match_case):
		if(text.find(search) == 0):
			_pass(disp)
		else:
			_fail(disp)
	else:
		if(text.to_lower().find(search.to_lower()) == 0):
			_pass(disp)
		else:
			_fail(disp)

# ------------------------------------------------------------------------------
# Assert that text ends with given search string.
# match_case flag determines case sensitivity.
# ------------------------------------------------------------------------------
func assert_string_ends_with(text, search, match_case=true):
	var empty_search = 'Expected text and search strings to be non-empty. You passed \'%s\' and \'%s\'.'
	var disp = 'Expected \'%s\' to end with \'%s\', match_case=%s' % [text, search, match_case]
	var required_index = len(text) - len(search)
	if(text == '' or search == ''):
		_fail(empty_search % [text, search])
	elif(match_case):
		if(text.find(search) == required_index):
			_pass(disp)
		else:
			_fail(disp)
	else:
		if(text.to_lower().find(search.to_lower()) == required_index):
			_pass(disp)
		else:
			_fail(disp)

# ------------------------------------------------------------------------------
# Assert that a method was called on an instance of a doubled class.  If
# parameters are supplied then the params passed in when called must match.
# TODO make 3rd parameter "param_or_text" and add fourth parameter of "text" and
#      then work some magic so this can have a "text" parameter without being
#      annoying.
# ------------------------------------------------------------------------------
func assert_called(inst, method_name, parameters=null):
	var disp = str('Expected [',method_name,'] to have been called on ',_str(inst))

	if(_fail_if_parameters_not_array(parameters)):
		return

	if(!_utils.is_double(inst)):
		_fail('You must pass a doubled instance to assert_called.  Check the wiki for info on using double.')
	else:
		if(gut.get_spy().was_called(inst, method_name, parameters)):
			_pass(disp)
		else:
			if(parameters != null):
				disp += str(' with parameters ', parameters)
			_fail(str(disp, "\n", _get_desc_of_calls_to_instance(inst)))

# ------------------------------------------------------------------------------
# Assert that a method was not called on an instance of a doubled class.  If
# parameters are specified then this will only fail if it finds a call that was
# sent matching parameters.
# ------------------------------------------------------------------------------
func assert_not_called(inst, method_name, parameters=null):
	var disp = str('Expected [', method_name, '] to NOT have been called on ', _str(inst))

	if(_fail_if_parameters_not_array(parameters)):
		return

	if(!_utils.is_double(inst)):
		_fail('You must pass a doubled instance to assert_not_called.  Check the wiki for info on using double.')
	else:
		if(gut.get_spy().was_called(inst, method_name, parameters)):
			if(parameters != null):
				disp += str(' with parameters ', parameters)
			_fail(str(disp, "\n", _get_desc_of_calls_to_instance(inst)))
		else:
			_pass(disp)

# ------------------------------------------------------------------------------
# Assert that a method on an instance of a doubled class was called a number
# of times.  If parameters are specified then only calls with matching
# parameter values will be counted.
# ------------------------------------------------------------------------------
func assert_call_count(inst, method_name, expected_count, parameters=null):
	var count = gut.get_spy().call_count(inst, method_name, parameters)

	if(_fail_if_parameters_not_array(parameters)):
		return

	var param_text = ''
	if(parameters):
		param_text = ' with parameters ' + str(parameters)
	var disp = 'Expected [%s] on %s to be called [%s] times%s.  It was called [%s] times.'
	disp = disp % [method_name, _str(inst), expected_count, param_text, count]

	if(!_utils.is_double(inst)):
		_fail('You must pass a doubled instance to assert_call_count.  Check the wiki for info on using double.')
	else:
		if(count == expected_count):
			_pass(disp)
		else:
			_fail(str(disp, "\n", _get_desc_of_calls_to_instance(inst)))

# ------------------------------------------------------------------------------
# Asserts the passed in value is null
# ------------------------------------------------------------------------------
func assert_null(got, text=''):
	var disp = str('Expected [', _str(got), '] to be NULL:  ', text)
	if(got == null):
		_pass(disp)
	else:
		_fail(disp)

# ------------------------------------------------------------------------------
# Asserts the passed in value is null
# ------------------------------------------------------------------------------
func assert_not_null(got, text=''):
	var disp = str('Expected [', _str(got), '] to be anything but NULL:  ', text)
	if(got == null):
		_fail(disp)
	else:
		_pass(disp)

# -----------------------------------------------------------------------------
# Asserts object has been freed from memory
# We pass in a title (since if it is freed, we lost all identity data)
# -----------------------------------------------------------------------------
func assert_freed(obj, title):
	var disp = title
	if(is_instance_valid(obj)):
		disp = _strutils.type2str(obj) + title
	assert_true(not is_instance_valid(obj), "Expected [%s] to be freed" % disp)

# ------------------------------------------------------------------------------
# Asserts Object has not been freed from memory
# -----------------------------------------------------------------------------
func assert_not_freed(obj, title):
	var disp = title
	if(is_instance_valid(obj)):
		disp = _strutils.type2str(obj) + title
	assert_true(is_instance_valid(obj), "Expected [%s] to not be freed" % disp)

# ------------------------------------------------------------------------------
# Asserts that the current test has not introduced any new orphans.  This only
# applies to the test code that preceedes a call to this method so it should be
# the last thing your test does.
# ------------------------------------------------------------------------------
func assert_no_new_orphans(text=''):
	var count = gut.get_orphan_counter().get_counter('test')
	var msg = ''
	if(text != ''):
		msg = ':  ' + text
	# Note that get_counter will return -1 if the counter does not exist.  This
	# can happen with a misplaced assert_no_new_orphans.  Checking for > 0
	# ensures this will not cause some weird failure.
	if(count > 0):
		_fail(str('Expected no orphans, but found ', count, msg))
	else:
		_pass('No new orphans found.' + msg)

# ------------------------------------------------------------------------------
# Returns a dictionary that contains
# - an is_valid flag whether validation was successful or not and
# - a message that gives some information about the validation errors.
# ------------------------------------------------------------------------------
func _validate_assert_setget_called_input(type, name_property
			, name_setter, name_getter):
	var obj = null
	var result = {"is_valid": true, "msg": ""}

	if null == type or typeof(type) != TYPE_OBJECT or not type.is_class("Resource"):
		result.is_valid = false
		result.msg = str("The type parameter should be a ressource, input is ", _str(type))
		return result

	if null == double(type):
		result.is_valid = false
		result.msg = str("Attempt to double the type parameter failed. The type parameter should be a ressource that can be doubled.")
		return result

	obj = _create_obj_from_type(type)
	var property = _find_object_property(obj, str(name_property))

	if null == property:
		result.is_valid = false
		result.msg += str("The property %s does not exist." % _str(name_property))
	if name_setter == "" and name_getter == "":
		result.is_valid = false
		result.msg += str("Either setter or getter method must be specified.")
	if name_setter != "" and not obj.has_method(str(name_setter)):
		result.is_valid = false
		result.msg += str("Setter method %s does not exist.  " % _str(name_setter))
	if name_getter != "" and not obj.has_method(str(name_getter)):
		result.is_valid = false
		result.msg += str("Getter method %s does not exist.  " %_str(name_getter))

	obj.free()
	return result

# ------------------------------------------------------------------------------
# Asserts the given setter and getter methods are called when the given property
# is accessed.
# ------------------------------------------------------------------------------
func _assert_setget_called(type, name_property, setter = "", getter  = ""):
	var name_setter = _utils.nvl(setter, "")
	var name_getter = _utils.nvl(getter, "")

	var validation = _validate_assert_setget_called_input(type, name_property, str(name_setter), str(name_getter))
	if not validation.is_valid:
		_fail(validation.msg)
		return

	var message = ""
	var amount_calls_setter = 0
	var amount_calls_getter = 0
	var expected_calls_setter = 0
	var expected_calls_getter = 0
	var obj = _create_obj_from_type(double(type))

	if name_setter != '':
		expected_calls_setter = 1
		stub(obj, name_setter).to_do_nothing()
		obj.set(name_property, null)
		amount_calls_setter = gut.get_spy().call_count(obj, str(name_setter))

	if name_getter != '':
		expected_calls_getter = 1
		stub(obj, name_getter).to_do_nothing()
		var new_property = obj.get(name_property)
		amount_calls_getter = gut.get_spy().call_count(obj, str(name_getter))

	obj.free()

	# assert

	if amount_calls_setter == expected_calls_setter and amount_calls_getter == expected_calls_getter:
		_pass(str("setget for %s is correctly configured." % _str(name_property)))
	else:
		if amount_calls_setter < expected_calls_setter:
			message += " The setter was not called."
		elif amount_calls_setter > expected_calls_setter:
			message += " The setter was called but should not have been."
		if amount_calls_getter < expected_calls_getter:
			message += " The getter was not called."
		elif amount_calls_getter > expected_calls_getter:
			message += " The getter was called but should not have been."
		_fail(str(message))

# ------------------------------------------------------------------------------
# Wrapper: invokes assert_setget_called but provides a slightly more convenient
# signature
# ------------------------------------------------------------------------------
func assert_setget(
	instance, name_property,
	const_or_setter = DEFAULT_SETTER_GETTER, getter="__not_set__"):

	var getter_name = null
	if(getter != "__not_set__"):
		getter_name = getter

	var setter_name = null
	if(typeof(const_or_setter) == TYPE_INT):
		if(const_or_setter in [SETTER_ONLY, DEFAULT_SETTER_GETTER]):
			setter_name  = str("set_", name_property)

		if(const_or_setter in [GETTER_ONLY, DEFAULT_SETTER_GETTER]):
			getter_name = str("get_", name_property)
	else:
		setter_name = const_or_setter

	var resource = null
	if instance.is_class("Resource"):
		resource = instance
	else:
		resource = _get_type_from_obj(instance)

	_assert_setget_called(resource, str(name_property), setter_name, getter_name)


# ------------------------------------------------------------------------------
# Wrapper: asserts if the property exists, the accessor methods exist and the
# setget keyword is set for accessor methods
# ------------------------------------------------------------------------------
func assert_property(instance, name_property, default_value, new_value) -> void:
	var free_me = []
	var resource = null
	var obj = null
	if instance.is_class("Resource"):
		resource = instance
		obj = _create_obj_from_type(resource)
		free_me.append(obj)
	else:
		resource = _get_type_from_obj(instance)
		obj = instance

	var name_setter = "set_" + str(name_property)
	var name_getter = "get_" + str(name_property)

	var pre_fail_count = get_fail_count()
	assert_accessors(obj, str(name_property), default_value, new_value)
	_assert_setget_called(resource, str(name_property), name_setter, name_getter)

	for entry in free_me:
		entry.free()

	# assert
	if get_fail_count() == pre_fail_count:
		_pass(str("The property is set up as expected."))
	else:
		_fail(str("The property is not set up as expected. Examine subtests to see what failed."))


# ------------------------------------------------------------------------------
# Mark the current test as pending.
# ------------------------------------------------------------------------------
func pending(text=""):
	_summary.pending += 1
	if(gut):
		_lgr.pending(text)
		gut._pending(text)

# ------------------------------------------------------------------------------
# Returns the number of times a signal was emitted.  -1 returned if the object
# is not being watched.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Yield for the time sent in.  The optional message will be printed when
# Gut detects the yield.  When the time expires the YIELD signal will be
# emitted.
# ------------------------------------------------------------------------------
func yield_for(time, msg=''):
	return gut.set_yield_time(time, msg)

# ------------------------------------------------------------------------------
# Yield to a signal or a maximum amount of time, whichever comes first.  When
# the conditions are met the YIELD signal will be emitted.
# ------------------------------------------------------------------------------
func yield_to(obj, signal_name, max_wait, msg=''):
	watch_signals(obj)
	gut.set_yield_signal_or_time(obj, signal_name, max_wait, msg)

	return gut

# ------------------------------------------------------------------------------
# Ends a test that had a yield in it.  You only need to use this if you do
# not make assertions after a yield.
# ------------------------------------------------------------------------------
func end_test():
	_lgr.deprecated('end_test is no longer necessary, you can remove it.')
	#gut.end_yielded_test()

func get_summary():
	return _summary

func get_fail_count():
	return _summary.failed

func get_pass_count():
	return _summary.passed

func get_pending_count():
	return _summary.pending

func get_assert_count():
	return _summary.asserts

func clear_signal_watcher():
	_signal_watcher.clear()

func get_double_strategy():
	return gut.get_doubler().get_strategy()

func set_double_strategy(double_strategy):
	gut.get_doubler().set_strategy(double_strategy)

func pause_before_teardown():
	gut.pause_before_teardown()

# ------------------------------------------------------------------------------
# Convert the _summary dictionary into text
# ------------------------------------------------------------------------------
func get_summary_text():
	var to_return = get_script().get_path() + "\n"
	to_return += str('  ', _summary.passed, ' of ', _summary.asserts, ' passed.')
	if(_summary.pending > 0):
		to_return += str("\n  ", _summary.pending, ' pending')
	if(_summary.failed > 0):
		to_return += str("\n  ", _summary.failed, ' failed.')
	return to_return

# ------------------------------------------------------------------------------
# Double a script, inner class, or scene using a path or a loaded script/scene.
#
#
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
func _smart_double(double_info):
	var override_strat = _utils.nvl(double_info.strategy, gut.get_doubler().get_strategy())
	var to_return = null

	if(double_info.is_scene()):
		if(double_info.make_partial):
			to_return =  gut.get_doubler().partial_double_scene(double_info.path, override_strat)
		else:
			to_return =  gut.get_doubler().double_scene(double_info.path, override_strat)

	elif(double_info.is_native()):
		if(double_info.make_partial):
			to_return = gut.get_doubler().partial_double_gdnative(double_info.path)
		else:
			to_return = gut.get_doubler().double_gdnative(double_info.path)

	elif(double_info.is_script()):
		if(double_info.subpath == null):
			if(double_info.make_partial):
				to_return = gut.get_doubler().partial_double(double_info.path, override_strat)
			else:
				to_return = gut.get_doubler().double(double_info.path, override_strat)
		else:
			if(double_info.make_partial):
				to_return = gut.get_doubler().partial_double_inner(double_info.path, double_info.subpath, override_strat)
			else:
				to_return = gut.get_doubler().double_inner(double_info.path, double_info.subpath, override_strat)
	return to_return

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
func double(thing, p2=null, p3=null):
	var double_info = DoubleInfo.new(thing, p2, p3)
	if(!double_info.is_valid):
		_lgr.error('double requires a class or path, you passed an instance:  ' + _str(thing))
		return null

	double_info.make_partial = false

	return _smart_double(double_info)

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
func partial_double(thing, p2=null, p3=null):
	var double_info = DoubleInfo.new(thing, p2, p3)
	if(!double_info.is_valid):
		_lgr.error('partial_double requires a class or path, you passed an instance:  ' + _str(thing))
		return null

	double_info.make_partial = true

	return _smart_double(double_info)


# ------------------------------------------------------------------------------
# Specifically double a scene
# ------------------------------------------------------------------------------
func double_scene(path, strategy=null):
	var override_strat = _utils.nvl(strategy, gut.get_doubler().get_strategy())
	return gut.get_doubler().double_scene(path, override_strat)

# ------------------------------------------------------------------------------
# Specifically double a script
# ------------------------------------------------------------------------------
func double_script(path, strategy=null):
	var override_strat = _utils.nvl(strategy, gut.get_doubler().get_strategy())
	return gut.get_doubler().double(path, override_strat)

# ------------------------------------------------------------------------------
# Specifically double an Inner class in a a script
# ------------------------------------------------------------------------------
func double_inner(path, subpath, strategy=null):
	var override_strat = _utils.nvl(strategy, gut.get_doubler().get_strategy())
	return gut.get_doubler().double_inner(path, subpath, override_strat)

# ------------------------------------------------------------------------------
# Add a method that the doubler will ignore.  You can pass this the path to a
# script or scene or a loaded script or scene.  When running tests, these
# ignores are cleared after every test.
# ------------------------------------------------------------------------------
func ignore_method_when_doubling(thing, method_name):
	var double_info = DoubleInfo.new(thing)
	var path = double_info.path

	if(double_info.is_scene()):
		var inst = thing.instantiate()
		if(inst.get_script()):
			path = inst.get_script().get_path()

	gut.get_doubler().add_ignored_method(path, method_name)

# ------------------------------------------------------------------------------
# Stub something.
#
# Parameters
# 1: the thing to stub, a file path or a instance or a class
# 2: either an inner class subpath or the method name
# 3: the method name if an inner class subpath was specified
# NOTE:  right now we cannot stub inner classes at the path level so this should
#        only be called with two parameters.  I did the work though so I'm going
#        to leave it but not update the wiki.
# ------------------------------------------------------------------------------
func stub(thing, p2, p3=null):
	if(_utils.is_instance(thing) and !_utils.is_double(thing)):
		_lgr.error(str('You cannot use stub on ', _str(thing), ' because it is not a double.'))
		return _utils.StubParams.new()

	var method_name = p2
	var subpath = null
	if(p3 != null):
		subpath = p2
		method_name = p3

	var sp = _utils.StubParams.new(thing, method_name, subpath)
	gut.get_stubber().add_stub(sp)
	return sp

# ------------------------------------------------------------------------------
# convenience wrapper.
# ------------------------------------------------------------------------------
func simulate(obj, times, delta):
	gut.simulate(obj, times, delta)

# ------------------------------------------------------------------------------
# Replace the node at base_node.get_node(path) with with_this.  All references
# to the node via $ and get_node(...) will now return with_this.  with_this will
# get all the groups that the node that was replaced had.
#
# The node that was replaced is queued to be freed.
#
# TODO see replace_by method, this could simplify the logic here.
# ------------------------------------------------------------------------------
func replace_node(base_node, path_or_node, with_this):
	var path = path_or_node

	if(typeof(path_or_node) != TYPE_STRING):
		# This will cause an engine error if it fails.  It always returns a
		# NodePath, even if it fails.  Checking the name count is the only way
		# I found to check if it found something or not (after it worked I
		# didn't look any farther).
		path = base_node.get_path_to(path_or_node)
		if(path.get_name_count() == 0):
			_lgr.error('You passed an object that base_node does not have.  Cannot replace node.')
			return

	if(!base_node.has_node(path)):
		_lgr.error(str('Could not find node at path [', path, ']'))
		return

	var to_replace = base_node.get_node(path)
	var parent = to_replace.get_parent()
	var replace_name = to_replace.get_name()

	parent.remove_child(to_replace)
	parent.add_child(with_this)
	with_this.set_name(replace_name)
	with_this.set_owner(parent)

	var groups = to_replace.get_groups()
	for i in range(groups.size()):
		with_this.add_to_group(groups[i])

	to_replace.queue_free()


# ------------------------------------------------------------------------------
# This method does a somewhat complicated dance with Gut.  It assumes that Gut
# will clear its parameter handler after it finishes calling a parameterized test
# enough times.
# ------------------------------------------------------------------------------
func use_parameters(params):
	var ph = gut.get_parameter_handler()
	if(ph == null):
		ph = _utils.ParameterHandler.new(params)
		gut.set_parameter_handler(ph)

	var output = str('(call #', ph.get_call_count() + 1, ') with paramters:  ', ph.get_current_parameters())
	_lgr.log(output)
	_lgr.inc_indent()
	return ph.next_parameters()

# ------------------------------------------------------------------------------
# Marks whatever is passed in to be freed after the test finishes.  It also
# returns what is passed in so you can save a line of code.
#   var thing = autofree(Thing.new())
# ------------------------------------------------------------------------------
func autofree(thing):
	gut.get_autofree().add_free(thing)
	return thing

# ------------------------------------------------------------------------------
# Works the same as autofree except queue_free will be called on the object
# instead.  This also imparts a brief pause after the test finishes so that
# the queued object has time to free.
# ------------------------------------------------------------------------------
func autoqfree(thing):
	gut.get_autofree().add_queue_free(thing)
	return thing

# ------------------------------------------------------------------------------
# The same as autofree but it also adds the object as a child of the test.
# ------------------------------------------------------------------------------
func add_child_autofree(node, legible_unique_name = false):
	gut.get_autofree().add_free(node)
	# Explicitly calling super here b/c add_child MIGHT change and I don't want
	# a bug sneaking its way in here.
	super.add_child(node, legible_unique_name)
	return node

# ------------------------------------------------------------------------------
# The same as autoqfree but it also adds the object as a child of the test.
# ------------------------------------------------------------------------------
func add_child_autoqfree(node, legible_unique_name=false):
	gut.get_autofree().add_queue_free(node)
	# Explicitly calling super here b/c add_child MIGHT change and I don't want
	# a bug sneaking its way in here.
	super.add_child(node, legible_unique_name)
	return node

# ------------------------------------------------------------------------------
# Returns true if the test is passing as of the time of this call.  False if not.
# ------------------------------------------------------------------------------
func is_passing():
	if(gut.get_current_test_object() != null and
		!['before_all', 'after_all'].has(gut.get_current_test_object().name)):
		return gut.get_current_test_object().passed and \
			gut.get_current_test_object().assert_count > 0
	else:
		_lgr.error('No current test object found.  is_passing must be called inside a test.')
		return null

# ------------------------------------------------------------------------------
# Returns true if the test is failing as of the time of this call.  False if not.
# ------------------------------------------------------------------------------
func is_failing():
	if(gut.get_current_test_object() != null and
		!['before_all', 'after_all'].has(gut.get_current_test_object().name)):
		return !gut.get_current_test_object().passed
	else:
		_lgr.error('No current test object found.  is_failing must be called inside a test.')
		return null

# ------------------------------------------------------------------------------
# Marks the test as passing.  Does not override any failing asserts or calls to
# fail_test.  Same as a passing assert.
# ------------------------------------------------------------------------------
func pass_test(text):
	_pass(text)

# ------------------------------------------------------------------------------
# Marks the test as failing.  Same as a failing assert.
# ------------------------------------------------------------------------------
func fail_test(text):
	_fail(text)

# ------------------------------------------------------------------------------
# Peforms a deep compare on both values, a CompareResult instnace is returned.
# The optional max_differences paramter sets the max_differences to be displayed.
# ------------------------------------------------------------------------------
func compare_deep(v1, v2, max_differences=null):
	var result = _compare.deep(v1, v2)
	if(max_differences != null):
		result.max_differences = max_differences
	return result

# ------------------------------------------------------------------------------
# Peforms a shallow compare on both values, a CompareResult instnace is returned.
# The optional max_differences paramter sets the max_differences to be displayed.
# ------------------------------------------------------------------------------
func compare_shallow(v1, v2, max_differences=null):
	var result = _compare.shallow(v1, v2)
	if(max_differences != null):
		result.max_differences = max_differences
	return result

# ------------------------------------------------------------------------------
# Performs a deep compare and asserts the  values are equal
# ------------------------------------------------------------------------------
func assert_eq_deep(v1, v2):
	var result = compare_deep(v1, v2)
	if(result.are_equal):
		_pass(result.get_short_summary())
	else:
		_fail(result.summary)

# ------------------------------------------------------------------------------
# Performs a deep compare and asserts the values are not equal
# ------------------------------------------------------------------------------
func assert_ne_deep(v1, v2):
	var result = compare_deep(v1, v2)
	if(!result.are_equal):
		_pass(result.get_short_summary())
	else:
		_fail(result.get_short_summary())

# ------------------------------------------------------------------------------
# Performs a shallow compare and asserts the values are equal
# ------------------------------------------------------------------------------
func assert_eq_shallow(v1, v2):
	var result = compare_shallow(v1, v2)
	if(result.are_equal):
		_pass(result.get_short_summary())
	else:
		_fail(result.summary)

# ------------------------------------------------------------------------------
# Performs a shallow compare and asserts the values are not equal
# ------------------------------------------------------------------------------
func assert_ne_shallow(v1, v2):
	var result = compare_shallow(v1, v2)
	if(!result.are_equal):
		_pass(result.get_short_summary())
	else:
		_fail(result.get_short_summary())
