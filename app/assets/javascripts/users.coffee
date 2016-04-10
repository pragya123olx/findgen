window.User = ->
	console.log("Creating User")

window.User.load = ->
	t = $('#users').DataTable()

	refreshUsers = (data) ->
	  t.clear().draw()
	  i = 0
	  while i < data.length
	    t.row.add([
	      data[i].name
	      data[i].location
	      data[i].email
	      data[i].phone_number
	      data[i].role_type
	    ]).draw()
	    i++

	showUsers = (user) ->
	  $.ajax(
	    url: '/users'
	    data: {role_type: user, client_id: clientId}
	    datatype: 'json').done((data) ->
	    refreshUsers data
	    return
	  ).fail (data) ->
	    console.log 'error'
	  types = [
	    'admin',
	    'spoc',
	    'vendor',
	    'owner'
	  ]
	  for type in types
	    if type == user
	      $('#' + type).addClass 'active'
	    else
	      $('#' + type).removeClass 'active'

	showUsers('admin')

	$('#admin').click ->
	  showUsers 'admin'
	$('#spoc').click ->
	  showUsers 'spoc'
	$('#vendor').click ->
	  showUsers 'vendor'
	$('#owner').click ->
	  showUsers 'owner'
	$('#save_user').click ->
	  formData = user:
	    name: $('#user_name').val()
	    location: $('#user_location').val()
	    email: $('#user_email').val()
	    phone_number: $('#user_phone_number').val()
	    role_type: $('#role_type').val()
	    client_id: clientId
	  $.post(
	    url: '/users'
	    data: formData).done((data) ->
	    $('#createUser').modal 'hide'
	    showUsers 'admin'
	    return
	  ).fail (data) ->
	    console.log 'error'
