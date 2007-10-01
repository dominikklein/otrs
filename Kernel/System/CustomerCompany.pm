# --
# Kernel/System/CustomerCompany.pm - All customer company related function should be here eventually
# Copyright (C) 2001-2007 OTRS GmbH, http://otrs.org/
# --
# $Id: CustomerCompany.pm,v 1.4 2007-10-01 09:56:29 martin Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

package Kernel::System::CustomerCompany;

use strict;
use warnings;

use Kernel::System::Valid;

use vars qw(@ISA $VERSION);
$VERSION = qw($Revision: 1.4 $) [1];

=head1 NAME

Kernel::System::CustomerCompany - project lib

=head1 SYNOPSIS

All project functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create a object

    use Kernel::Config;
    use Kernel::System::Time;
    use Kernel::System::Log;
    use Kernel::System::DB;
    use Kernel::System::CustomerCompany;

    my $ConfigObject = Kernel::Config->new();
    my $TimeObject = Kernel::System::Time->new(
        ConfigObject => $ConfigObject,
    );
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
    );
    my $DBObject = Kernel::System::DB->new(
        ConfigObject => $ConfigObject,
        LogObject => $LogObject,
    );
    my $CustomerCompanyObject = Kernel::System::CustomerCompany->new(
        ConfigObject => $ConfigObject,
        LogObject => $LogObject,
        DBObject => $DBObject,
        TimeObject => $TimeObject,
    );

=cut

sub new {
    my $Type  = shift;
    my %Param = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for (qw(DBObject ConfigObject LogObject MainObject)) {
        $Self->{$_} = $Param{$_} || die "Got no $_!";
    }
    $Self->{ValidObject} = Kernel::System::Valid->new(%Param);

    # config options
    $Self->{CustomerCompanyTable} = $Self->{ConfigObject}->Get('CustomerCompany')->{Params}->{Table}
        || die "Need CustomerCompany->Params->Table in Kernel/Config.pm!";
    $Self->{CustomerCompanyKey}
        = $Self->{ConfigObject}->Get('CustomerCompany')->{CustomerCompanyKey}
        || $Self->{ConfigObject}->Get('CustomerCompany')->{Key}
        || die "Need CustomerCompany->CustomerCompanyKey in Kernel/Config.pm!";
    $Self->{CustomerCompanyMap} = $Self->{ConfigObject}->Get('CustomerCompany')->{Map}
        || die "Need CustomerCompany->Map in Kernel/Config.pm!";

    # create new db connect if DSN is given
    if ( $Self->{ConfigObject}->Get('CustomerCompany')->{Params}->{DSN} ) {
        $Self->{DBObject} = Kernel::System::DB->new(
            LogObject    => $Param{LogObject},
            ConfigObject => $Param{ConfigObject},
            MainObject   => $Param{MainObject},
            DatabaseDSN  => $Self->{ConfigObject}->Get('CustomerCompany')->{Params}->{DSN},
            DatabaseUser => $Self->{ConfigObject}->Get('CustomerCompany')->{Params}->{User},
            DatabasePw   => $Self->{ConfigObject}->Get('CustomerCompany')->{Params}->{Password},
            Type         => $Self->{ConfigObject}->Get('CustomerCompany')->{Params}->{Type} || '',
        ) || die('Can\'t connect to database!');

        # remember that we have the DBObject not from parent call
        $Self->{NotParentDBObject} = 1;
    }

    return $Self;
}

=item CustomerCompanyAdd()

add new projects

    my $ID = $CustomerCompanyObject->CustomerCompanyAdd(
        CustomerID => 'example.com',
        CustomerCompanyName => 'New Customer Company Inc.',
        CustomerCompanyStreet => '5201 Blue Lagoon Drive',
        CustomerCompanyZIP => '33126',
        CustomerCompanyLocation => 'Miami',
        CustomerCompanyCountry => 'USA',
        CustomerCompanyComment => 'some comment',
        ValidID => 1,
        UserID => 123,
    );

=cut

sub CustomerCompanyAdd {
    my $Self  = shift;
    my %Param = @_;

    # check needed stuff
    for (qw(CustomerID UserID)) {
        if ( !$Param{$_} ) {
            $Self->{LogObject}->Log( Priority => 'error', Message => "Need $_!" );
            return;
        }
    }

    # build insert
    my $SQL = "INSERT INTO $Self->{CustomerCompanyTable} (";
    for my $Entry ( @{ $Self->{CustomerCompanyMap} } ) {
        $SQL .= " $Entry->[2], ";
    }
    $SQL .= "create_time, create_by, change_time, change_by)";
    $SQL .= " VALUES (";
    for my $Entry ( @{ $Self->{CustomerCompanyMap} } ) {
        if ( $Entry->[5] =~ /^int$/i ) {
            $SQL .= " " . $Self->{DBObject}->Quote( $Param{ $Entry->[0] } ) . ", ";
        }
        else {
            $SQL .= " '" . $Self->{DBObject}->Quote( $Param{ $Entry->[0] } ) . "', ";
        }
    }
    $SQL .= "current_timestamp, $Param{UserID}, current_timestamp, $Param{UserID})";
    if ( $Self->{DBObject}->Do( SQL => $SQL ) ) {

        # log notice
        $Self->{LogObject}->Log(
            Priority => 'notice',
            Message =>
                "CustomerCompany: '$Param{CustomerCompanyName}/$Param{CustomerID}' created successfully ($Param{UserID})!",
        );
        return $Param{CustomerID};
    }
    else {
        return;
    }
}

=item CustomerCompanyGet()

get projects attributes

    my %CustomerCompany = $CustomerCompanyObject->CustomerCompanyGet(
        CustomerID => 123,
    );

=cut

sub CustomerCompanyGet {
    my $Self  = shift;
    my %Param = @_;
    my %Data  = ();

    # check needed stuff
    if ( !$Param{CustomerID} ) {
        $Self->{LogObject}->Log( Priority => 'error', Message => "Need CustomerID!" );
        return;
    }

    # build select
    my $SQL = "SELECT ";
    for my $Entry ( @{ $Self->{CustomerCompanyMap} } ) {
        $SQL .= " $Entry->[2], ";
    }
    $SQL .= $Self->{CustomerCompanyKey}
        . ", change_time, create_time FROM $Self->{CustomerCompanyTable} WHERE ";
    if ( $Param{Name} ) {
        $SQL .= "LOWER($Self->{CustomerCompanyKey}) = LOWER('"
            . $Self->{DBObject}->Quote( $Param{Name} ) . "')";
    }
    elsif ( $Param{CustomerID} ) {
        $SQL .= "LOWER($Self->{CustomerCompanyKey}) = LOWER('"
            . $Self->{DBObject}->Quote( $Param{CustomerID} ) . "')";
    }

    # get initial data
    $Self->{DBObject}->Prepare( SQL => $SQL );
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        my $MapCounter = 0;
        for my $Entry ( @{ $Self->{CustomerCompanyMap} } ) {
            $Data{ $Entry->[0] } = $Row[$MapCounter];
            $MapCounter++;
        }
        $MapCounter++;
        $Data{ChangeTime} = $Row[$MapCounter];
        $MapCounter++;
        $Data{CreateTime} = $Row[$MapCounter];
    }

    # return data
    return %Data;
}

=item CustomerCompanyUpdate()

update project attributes

    $CustomerCompanyObject->CustomerCompanyUpdate(
        CustomerID => 'example.com',
        CustomerCompanyName => 'New Customer Company Inc.',
        CustomerCompanyStreet => '5201 Blue Lagoon Drive',
        CustomerCompanyZIP => '33126',
        CustomerCompanyLocation => 'Miami',
        CustomerCompanyCountry => 'USA',
        CustomerCompanyComment => 'some comment',
        ValidID => 1,
        UserID => 123,
    );

=cut

sub CustomerCompanyUpdate {
    my $Self  = shift;
    my %Param = @_;

    # check needed stuff
    for my $Entry ( @{ $Self->{CustomerCompanyMap} } ) {
        if ( !$Param{ $Entry->[0] } && $Entry->[4] && $Entry->[0] ne 'UserPassword' ) {
            $Self->{LogObject}->Log( Priority => 'error', Message => "Need $Entry->[0]!" );
            return;
        }
    }

    # update db
    my $SQL = "UPDATE $Self->{CustomerCompanyTable} SET ";
    for my $Entry ( @{ $Self->{CustomerCompanyMap} } ) {
        if ( $Entry->[5] =~ /^int$/i ) {
            $SQL .= " $Entry->[2] = " . $Self->{DBObject}->Quote( $Param{ $Entry->[0] } ) . ", ";
        }
        elsif ( $Entry->[0] !~ /^UserPassword$/i ) {
            $SQL .= " $Entry->[2] = '" . $Self->{DBObject}->Quote( $Param{ $Entry->[0] } ) . "', ";
        }
    }
    $SQL .= " change_time = current_timestamp, ";
    $SQL .= " change_by = $Param{UserID} ";
    $SQL .= " WHERE LOWER($Self->{CustomerCompanyKey}) = LOWER('"
        . $Self->{DBObject}->Quote( $Param{CustomerID} ) . "')";

    if ( $Self->{DBObject}->Do( SQL => $SQL ) ) {

        # log notice
        $Self->{LogObject}->Log(
            Priority => 'notice',
            Message =>
                "CustomerCompany: '$Param{CustomerCompanyName}/$Param{CustomerID}' updated successfully ($Param{UserID})!",
        );
        return 1;
    }
    else {
        return;
    }
}

=item CustomerCompanyList()

get project list

    my %List = $CustomerCompanyObject->CustomerCompanyList();

    my %List = $CustomerCompanyObject->CustomerCompanyList(
        Valid => 0,
    );

=cut

sub CustomerCompanyList {
    my $Self  = shift;
    my %Param = @_;
    my $Valid = 1;

    # check needed stuff
    if ( !$Param{Valid} && defined( $Param{Valid} ) ) {
        $Valid = 0;
    }
    my $What = '';
    for ( @{ $Self->{ConfigObject}->Get('CustomerCompany')->{CustomerCompanyListFields} } ) {
        if ($What) {
            $What .= ', ';
        }
        $What .= "$_";
    }

    # sql
    return $Self->{DBObject}->GetTableData(
        What  => "$Self->{CustomerCompanyKey}, $What",
        Valid => $Valid,
        Clamp => 1,
        Table => $Self->{CustomerCompanyTable},
    );
}

sub DESTROY {
    my $Self = shift;

    # disconnect if it's not a parent DBObject
    if ( $Self->{NotParentDBObject} ) {
        if ( $Self->{DBObject} ) {
            $Self->{DBObject}->Disconnect();
        }
    }
    return 1;
}

1;

=back

=head1 TERMS AND CONDITIONS

This Software is part of the OTRS project (http://otrs.org/).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see http://www.gnu.org/licenses/gpl.txt.

=cut

=head1 VERSION

$Revision: 1.4 $ $Date: 2007-10-01 09:56:29 $

=cut
