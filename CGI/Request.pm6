use CGI::Response;

class CGI::Request {
	my %ENV; # again, should have a ., but rakudo bug
	has %.ENV is r; # a copy for local use (e.g. .perl)

	my $RequestObject;

	has Hash %.Params is r;

	# TODO This should probably be Buf
	my $Content; # static
	has Str $.Content is r;

	submethod BUILD() {
		if $Content ~~ Any {
			# Done on first object creation, after that it returns content statically
			readStdIn();
		}
		if $RequestObject ~~ Any {
			# In case someone else subclasses us, since GetRequest may never be called
			build_environment_vars();
		}

		$!Content := $Content;
		%!ENV := %ENV;
	}

	method GetRequest returns CGI::Request {
		# Cache the request object so multiple calls return the same thing
		return $RequestObject if $RequestObject;

		# Build the environment vars in the static class
		build_environment_vars();

		# And return the correct object type
		if %ENV<REQUEST_METHOD> ~~ /GET/ {
			$RequestObject = ::CGI::Request::GET.new();
		} elsif %ENV<REQUEST_METHOD> ~~ /POST/ {
			$RequestObject = ::CGI::Request::POST.new();
		} else {
			# All others, e.g. PUT
			warn "Consider adding dedicated handler class for HTTP request type '" ~ %ENV<REQUEST_METHOD> ~ "'";
			$RequestObject = CGI::Request.new();
		}
		return $RequestObject;
	}

	sub build_environment_vars() {
		# rakudo workaround, import environment variables from system env
		%ENV = ();
		my $vars = qqx{env};
		my @lines = $vars.split(/\n/);
		for @lines -> $line {
			next if $line.match(/$^/);
			my @parts = $line.split(/\=/,2);
			my $varname = @parts[0];
			my $varvalue = @parts[1];
			%ENV{$varname} = $varvalue;
		}
	}

	sub readStdIn() {
		if not defined %ENV<CONTENT_LENGTH> {
			$Content = '';
			%ENV<CONTENT_LENGTH> = 0;
			return;
		}

		$Content = '';

		return if %ENV<CONTENT_LENGTH> eq 0;

		# TODO need to use binary STDIN (when Rakudo supports it!)
		try {
			for $*IN.lines -> $line {
				$Content ~= $line ~ "\n";
			}
			CATCH {
				fatal "An exception occured reading STDIN: $!";
			}
		}
	}

	method GetResponse() returns CGI::Response {
		my CGI::Response $response = CGI::Response.new();
		return $response;
	}
}

class CGI::Request::GET is CGI::Request {

       submethod BUILD() {
               # Parse GET query
               $.parse_get_query();
       }

       method parse_get_query() {
               my $query = %.ENV<QUERY_STRING>;

               my @parts = $query.split(/\&/);
               for @parts -> $part {
                       my @kv = $part.split(/ \= /, 2);
                       %!Params{@kv[0]} = @kv[1];
               }
       }

}

class CGI::Request::POST is CGI::Request {

	has Bool $.Multipart is r;
	has Str $.MultipartType is r;
	has Str $.Boundary is r;

	submethod BUILD() {
		# Parse POST query
		$.parse_post_query();
	}

	method parse_post_query() {
		my $query = $!Content;

		# Get rid of the trailing \n from the HTTP connection
		$query ~~= s/ \n$ //, :g;
	
		# Check for multipart submissions
		if %!ENV<CONTENT_TYPE> ~~ m/ ^ multipart \/ (.*?) \; \s boundary \= (.*) / {
			$!Boundary = $/.[1].Str;
			$!Multipart = True;
			$!MultipartType = $/.[0].Str;

			# RFC1341, 7.2 Multipart
			my $actualBoundary = '--' ~ $!Boundary;

			# Strip the end marker, it'll confuse the MultipartData object
			$query ~~= s/ $actualBoundary \-\- $ //;

			my @multiparts = $query.split($actualBoundary ~ "\n");
			my $pc = 0;
			for @multiparts -> $multipart {
				next if $multipart.chars == 0;

				$pc++;
				my $mp = ::CGI::Request::POST::MultipartData.new( :MultipartData($multipart) );
				my $mpname = "Multipart" ~ $pc;
				if $mp.Name !~~ / ^ $ / {
					$mpname = $mp.Name;
				}
				%!Params{$mpname} = $mp;
			}

			return;		
		}

		# Only get here if none of the multipart bits above match
		# in which case we (hopefully) have a normal field=value&... request
		$!Multipart = False;
		$!MultipartType = Mu;
		$!Boundary = "&";

		my @parts;
		@parts = $query.split($!Boundary);
		for @parts -> $part {
			my @kv = $part.split(/ \= /, 2);
			%!Params{@kv[0]} = @kv[1];
		}
	}

}

class CGI::Request::POST::MultipartData {
	has %.Headers is r;
	has $.Name is r;
	has $.Value is r;

	has $.MultipartData is r;

	submethod BUILD(Str $!MultipartData) {
		my $realdata = $!MultipartData;

		if $!MultipartData !~~ / ^ \n / {
			# has probably got headers
			for $!MultipartData.lines -> $line {
				last if $line ~~ / ^ $ /;

				my $match = $line ~~ / (.*?) \: \s (.*) /;
				my $header = $match.[0].Str;
				my $value = $match.[1].Str;
				%!Headers{$header} = $value;

				if $header ~~ / Content\-Disposition /, :i {
					# TODO regex below is broke!
					# Could include filename=something
					if $value ~~ / .*? name \= \" (.*?) \" / {
						$!Name = $/.[0].Str;
					}
				}

				$realdata = $!MultipartData.substr($match.[1].to);
			}
		}

		$realdata ~~= s/ ^ \n* //;
		$realdata ~~= s/ \n $ //;
		$!Value = $realdata;
	}
}
