# --
# Copyright (C) 2001-2019 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::SupportDataCollector::Plugin::Database::postgresql::Size;

use strict;
use warnings;

use base qw(Kernel::System::SupportDataCollector::PluginBase);

sub GetDisplayPath {
    return 'Database';
}

sub Run {
    my $Self = shift;

    if ( $Self->{DBObject}->GetDatabaseFunction('Type') !~ m{^postgresql} ) {
        return $Self->GetResults();
    }

    # version check
    $Self->{DBObject}->Prepare(
        SQL   => "SELECT pg_size_pretty(pg_database_size(current_database()))",
        LIMIT => 1,
    );
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {

        if ( $Row[0] ) {
            $Self->AddResultInformation(
                Label => 'Database Size',
                Value => $Row[0],
            );
        }
        else {
            $Self->AddResultProblem(
                Label   => 'Database Size',
                Value   => $Row[0],
                Message => 'Could not determine database size.'
            );
        }
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
