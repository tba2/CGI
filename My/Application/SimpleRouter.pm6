class My::Application::SimpleRouter is CGI::Application::Router {

	# Implement the GetRoute method - it returns a class/method combination
	method GetRoute() {
		# Get the base namespace to prepend to any handler names
                my $appBase = $!Application.Configuration.DefaultBase ~ "::";

		# Return some known URL's
                return $appBase ~ "Default::_About" if $!Application.ENV<REQUEST_URI> ~~ / ^ \/ about /;
		return $appBase ~ "Default::_Welcome" if $!Application.ENV<REQUEST_URI> ~~ / ^ \/ (\?.*)? $ /;

		# Otherwise return the DefaultHandler (probably _404NotFound)
                return $appBase ~ $!Application.Configuration.DefaultHandler;
	}

}
