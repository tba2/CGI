class My::Application::YAMLRouter is CGI::Application::Router {

	method GetRoute() {
		# TODO Get all this stuff from the .yml file!

                my $appBase = $!Application.Configuration.DefaultBase ~ "::";

                return $appBase ~ "Default::_About" if $!Application.ENV<REQUEST_URI> ~~ / ^ \/ about /;
		return $appBase ~ "Default::_Welcome" if $!Application.ENV<REQUEST_URI> ~~ / ^ \/ (\?.*)? $ /;

                return $appBase ~ $!Application.Configuration.DefaultHandler;
	}

}
