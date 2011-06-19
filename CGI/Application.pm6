use Dumper;
use CGI::Request;
use CGI::Response;

class CGI::Application is CGI::Request {

	has CGI::Request $.Request = Any;
	has CGI::Response $.Response = Any;
	has ::CGI::Application::Configuration $.Configuration = Any;

	has Bool $.DebugMode;

	has $.RouterClass;

	submethod BUILD( CGI::Application::Configuration $!Configuration ) {
		$!Request = CGI::Request.GetRequest();
		$!Response = $!Request.GetResponse();

		$!DebugMode = True;
		$!RouterClass = $!Configuration.DefaultRouter;

		# Include document root in @*INC
		unshift @*INC, %!ENV<DOCUMENT_ROOT>;
	}

	# XXX Probably doesn't need to remain, but its quicker and easier than calling Dumper.dumper all the time!
	# TODO what about aliasing?!
	method Dump(Any $object) {
		$!Response.WriteLine(Dumper.dumper($object));
	}

	method Route() {
		# TODO Enable exception handling once things (including Rakudo) are a bit more stable
		#try {
			my $route = $.getRoute();
			$route ~~ / ^ (.*) \: \: (.*?) $ /;
			my $class = $/.[0].Str;
			my $handler = $/.[1].Str;

			# Load class and invoke handler
			if $class !~~ /CGI\:\:Application\:\:Handler/ {
				require $class;
			}
			my $handlerObj = eval($class).new( :Application(self) );
			$handlerObj."$handler"();

			$!Response.Output();

	#		CATCH {
	#			$!Response.Clear();
	#			$!Response.SetHeader('Status', 500);
	#			if $!DebugMode {
	#				$!Response.WriteLine("An exception has occured:");
	#				$!Response.WriteLine("$!");
	#			} 
	#			$!Response.Output();
	#		}
		#}
	}

	method getRoute() {
		# Find out which Router class to use from config (when it exists TODO)
		my $class = $!RouterClass;
		if $class !~~ /CGI\:\:Application\:\:Router/ {
			require $class;
		}
		my $router = eval($class).new( :Application(self) );
		return $router.GetRoute();
	}
}

class CGI::Application::Handler {

	has CGI::Application $.Application;

	method DefaultHandler() {
		$.WriteLine("This is the default handler. You should implement your own Router and Handler classes.");
		$.WriteLine("");
		$.WriteLine("This is a dump of your application:");
		$.WriteLine("");
		$!Application.Dump($!Application);
	}

	method Write(Str $Text) { $!Application.Response.Write($Text); }
	method WriteLine(Str $Text) { $!Application.Response.WriteLine($Text); }
}

class CGI::Application::Router {

	has CGI::Application $.Application;

	method GetRoute() {
		# Return a default route (to the default handler) 
		return "CGI::Application::Handler::DefaultHandler";
	}
}

class CGI::Application::Configuration {
	has $.DefaultRouter;
	has $.DefaultBase;
	has $.DefaultHandler;

	submethod BUILD($!DefaultRouter, $!DefaultBase, $!DefaultHandler) {

	}
}
