# --
# Copyright (C) 2001-2019 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::SupportDataCollector::Plugin::OTRS::SystemID;

use strict;
use warnings;

use base qw(Kernel::System::SupportDataCollector::PluginBase);

sub GetDisplayPath {
    return 'OTRS';
}

sub Run {
    my $Self = shift;

    # Get the configured SystemID
    my $SystemID = $Self->{ConfigObject}->Get('SystemID');

    # Does the SystemID contain non-digits?
    if ( $SystemID !~ /^\d+$/ ) {
        $Self->AddResultProblem(
            Label   => 'SystemID',
            Value   => $SystemID,
            Message => 'Your SystemID setting is invalid, it should only contain digits.',
        );
    }
    else {
        $Self->AddResultOk(
            Label => 'SystemID',
            Value => $SystemID,
        );
    }

    return $Self->GetResults();
}

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut

1;
