class My::Application::Pages::Default is CGI::Application::Handler {

	method _Welcome() {
		$.Write("This is the Welcome page, handled by My::Application::Pages::Default::_Welcome");
	}

	method _About() {
		$.Write("This is the About page, handled by My::Application::Pages::Default::_About");
	}

	method _404NotFound() {
		$.Write("404 Not Found");
	}

}
