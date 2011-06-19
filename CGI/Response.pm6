class CGI::Response {
	# TODO define more default headers, use Any and don't output headers with value of Any!
	has %.Headers is r = (
		Content-Type		=> "text/plain",
		Content-Length		=> 0,
		Content-Disposition	=> Any,
		Status			=> 200, #OK
		Location		=> Any,
	);
	has $.Content is r;

	has $.Charset is r = "UTF-8";

	method SetHeader(Str $Header, Any $Value = "") {
		%!Headers{$Header} = $Value;
		return;
	}
	method DeleteHeader(Str $Header) {
		%!Headers.delete($Header);
		return;
	}
	method GetHeader(Str $Header) {
		return %!Headers{$Header};
	}

	method Clear() {
		$!Content = '';
		$!Headers<Content-Length> = 0;
		return;
	}
	method Write(Str $Content) {
		$!Content ~= $Content;
		%!Headers<Content-Length> = bytes $!Content;
		return;
	}
	method WriteLine(Str $Content) { return $.Write($Content ~ "\n"); }

	method Redirect(Str $Destination, Str :$Status = 302) {
		$.SetHeader("Location", $Destination);
		$.SetHeader("Status", 302);
		return $.Output;
	}

	method Output() {
		# Prepare the HTML - subclasses can hook into that without affecting Output
		$.Prepare();

		# Before we do anything, warn if the content-length doesn't match
		if (defined $!Content && bytes $!Content.match(%.Headers<Content-Length>)) {
			warn "Content-length header doesn't match length of content";
		}

		# Only warn if there's no content-type, it might be intentional!
		if !defined %!Headers<Content-Type> {
			warn "Content-Type header has been REMOVED - expect internal server errors!";
		}

		# If we have a Status header, that comes first!
		if defined %!Headers<Status> {
			my $status = %!Headers<Status>;

			# Check if we've got a recognised status code and grab the right text
			if defined %!HTTP_STATUS_CODES{$status} { $status ~= " " ~ %!HTTP_STATUS_CODES{$status}; }

			print "Status: " ~ $status ~ "\n";
		}

		# If we have a content-type, output it before any other headers (except Status obviously!)
		if defined %!Headers<Content-Type> {
			print "Content-Type: " ~ %!Headers<Content-Type> ~ "; charset=" ~ $!Charset ~ "\n";
		}

		# Now output the rest of the headers (except Content-Type and Status)
		for %!Headers.kv -> $header, $value {
			if ( $value eq Any || $header.match(/(Content\-Type|Status)/) ) { next; }
			print "$header: $value\n";
		}
		print "\n";

		# And finally output the content if there is any...
		print $!Content if defined $!Content;

		return;
	}

	method Prepare() { } # Override to do stuff just before content is output

	# Standard HTTP codes
	# Stolen from tadzik (who stole them from Mongrel!)
	has %.HTTP_STATUS_CODES is r = (
	      100 => 'Continue',
	      101 => 'Switching Protocols',
	      200 => 'OK',
	      201 => 'Created',
	      202 => 'Accepted',
	      203 => 'Non-Authoritative Information',
	      204 => 'No Content',
	      205 => 'Reset Content',
	      206 => 'Partial Content',
	      300 => 'Multiple Choices',
	      301 => 'Moved Permanently',
	      302 => 'Found',
	      303 => 'See Other',
	      304 => 'Not Modified',
	      305 => 'Use Proxy',
	      307 => 'Temporary Redirect',
	      400 => 'Bad Request',
	      401 => 'Unauthorized',
	      402 => 'Payment Required',
	      403 => 'Forbidden',
	      404 => 'Not Found',
	      405 => 'Method Not Allowed',
	      406 => 'Not Acceptable',
	      407 => 'Proxy Authentication Required',
	      408 => 'Request Timeout',
	      409 => 'Conflict',
	      410 => 'Gone',
	      411 => 'Length Required',
	      412 => 'Precondition Failed',
	      413 => 'Request Entity Too Large',
	      414 => 'Request-URI Too Large',
	      415 => 'Unsupported Media Type',
	      416 => 'Requested Range Not Satisfiable',
	      417 => 'Expectation Failed',
	      500 => 'Internal Server Error',
	      501 => 'Not Implemented',
	      502 => 'Bad Gateway',
	      503 => 'Service Unavailable',
	      504 => 'Gateway Timeout',
	      505 => 'HTTP Version Not Supported'
	);
}
