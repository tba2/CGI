class Dumper;

method dumper($object) {
	# Do some funny stuff with the .perl output to make it look nicer!
        my $text = $object.perl;

        my $output = '';
        my $indent = 0;

        my @chars = gather { take $text.substr($_, 1) for 0 .. $text.chars - 1; };

	my $inquote = 0;
	my $quoteterm = '"';
	my $prevchar = '';

        # TODO needs some improvement
        # can probably extract the entire lot using regex
        for @chars -> $char {
		if $char eq ' ' && $inquote == 0 {
			$prevchar = $char;
			next;
		}
		if $inquote == 0 && $char ~~ / \" | \' / {
			$quoteterm = $char;
			$inquote = 1;
			$output ~= $char;
		} elsif $inquote == 1 && $char eq $quoteterm {
			if $prevchar ne '\\' {
				$inquote = 0;
			}
			$output ~= $char;
                } elsif $inquote == 0 && $char ~~ / \( | \{ / {
                        $indent += 4;
                        $output ~= $char;
                        $output ~= "\n";
                        $output ~= " " x $indent;
                } elsif $inquote == 0 && $char ~~ / \) | \} / {
                        $indent -= 4;
                        $output ~= "\n";
                        $output ~= " " x $indent;
                        $output ~= $char;
                } elsif $inquote == 0 && $char ~~ / \, / {
                        $output ~= $char;
                        $output ~= "\n";
                        $output ~= " " x $indent;
                } elsif $inquote == 0 && $char ~~ / \= / {
                        $output ~= " ";
                        $output ~= $char;
                } elsif $inquote == 0 && $char ~~ / \> / && $prevchar ~~ / \= / {
                        $output ~= $char;
                        $output ~= " ";
                } else {
                        $output ~= $char;
                        if $char ~~ / \n / {
                                $output ~= " " x $indent;
                        }
                }
		$prevchar = $char;
        }

        return $output;
}

