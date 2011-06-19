#!/usr/bin/perl6

use v6;
use CGI::Application;

# Create a configuration object
my $config = CGI::Application::Configuration.new(
	:DefaultRouter("My::Application::SimpleRouter"),
	:DefaultBase("My::Application::Pages"),
	:DefaultHandler("Default::_404NotFound"),
);

# Create the application
my $application = CGI::Application.new( :Configuration($config) );

# Call the router
$application.Route();

# That's it - couldn't be easier!
