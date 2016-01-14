Rails Lite
Backend application framework inspired by Rails, includes ActiveRecord Lite, a lightweight version of ActiveRecord and an object-relational mapper (ORM) between Ruby and SQL.

The purpose of this Rails Lite project is to demonstrate understanding of MVC, the Ruby on Rails framework, and ActiveRecord-assisted SQL commands.

Server Infrastructure

Rails Lite is run Rack, located in /bin/server.rb, utilizing the Rack API to handle HTTP requests and responses.

Two custom middlewares are implemented through Rack: Stack Tracer and Static Assets.

Stack Tracer

The Stack Tracer is the first in the middleware stack to rescue all exceptions raised by any subsequent middlewares and app. It outputs a status 500 error, formatted in HTML, when any exception is raised.

Static Assets

Certain static assets are made accessible to the public by sending a GET request with /public/ included in the path after the hostname.

The Static Asset middleware matches the /public/ path and responds with the corresponding static asset, such as images and HTML files.

Architecture and MVC

Rails Lite includes a custom router, controller base, and model base.

Router

Through meta-programming, the router dynamically creates a route for each controller action. When passed a request, the router runs the responsible route to call on the corresponding controller action.

Controller Base

The Controller Base functions similarly to the ActionController::Base in Ruby on Rails. It is the super class that provides the standard controller methods (render, redirect_to, session, and flash). User-defined controller actions are invoked by the corresponding route.

Model Base

The Model Base serves as the base class for user-generated models. It is a lightweight version of the ActiveRecord::Base class in Ruby on Rails, used for ORM between Ruby and SQL.

Included methods are the standard queries:

#all
#find
#insert
#update
#save
In addition, inheriting from Model Base grants the #where method from the Searchable module, to dynamically query from the SQL RDBMS.

The Associatable module is extended as well, to provide the three standard methods for model associations:

belongs_to
has_many
has_one_through
Additional Features

Session

The client session is stored as a cookie through the Rack cookie-setter and getter methods. This allows the Rails app to authenticate user session upon receiving the HTTP request.

Flash

The Flash class is used to display notifications to the client, whether immediately or stored to be displayed after a redirect.

Flash#now is used for displaying notifications upon rendering a view. Meanwhile, the standard flash stores any object as a cookie in the response. This allows data (e.g. message strings) to persist through a redirect.
