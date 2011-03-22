package WormBase::API::ModelMap;

use strict;
use warnings;
use Module::Pluggable::Object;

# If we want to make this more object-oriented, we would add a class attribute
# (e.g. _ACE_MODEL) to WormBase::API::Object. That attribute would default to
# the model name and would be overridden for the special cases, e.g. Pcr_oligo,
# which maps to PCR_product, Oligo_set, Oligo. This class would then initialize
# the maps by accessing the _ACE_MODEL attributes of each model.

# In this more procedural approach, the special cases (e.g. Pcr_oligo) are hard-
# coded into the maps. The map is then populated with defaults.

{ # limit the scope of the lexical variables to prevent tampering
    my $base = 'WormBase::API::Object';

    my $WB2ACE_MAP_DONE = 0;
    my %WB2ACE_MAP = ( # WB models -> Ace models (values are Ace tags/values)
        class => { # remember to put on the base
            Pcr_oligo => [qw(PCR_product Oligo_set Oligo)],
            Sequence  => [qw(Sequence CDS)],
            Rnai      => 'RNAi',
        },
        common_name => {
            Person       => 'Standard_name',
            Gene         => [qw(Public_name CGC_name Molecular_name)],
            # for gene, still missing $gene->Corresponding_CDS->Corresponding_protein
            Feature      => ['Public_name', 'Other_name'],
            Variation    => 'Public_name',
            Phenotype    => 'Primary_name',
            Gene_class   => 'Main_name',
            Species      => 'Common_name',
            Molecule     => [qw(Public_name Name)],
            Anatomy_term => 'Term',
        },
        laboratory => {
            Gene_class  => 'Designating_laboratory',
            PCR_product => 'From_laboratory',
            Sequence    => 'From_laboratory',
            CDS         => 'From_laboratory',
            Transgene   => 'Location',
            Strain      => 'Location',
            Antibody    => 'Location',
        },
    );

    my $ACE2WB_MAP_DONE = 0;
    my %ACE2WB_MAP = ( # Ace models -> WB models (values are WB attrs/values)
    );

    sub _map_wb2ace {
        # canonize the existing entries
        while (my ($wbclass, $aceclass) = each %{$WB2ACE_MAP{class}}) {
            next if $wbclass =~ /^${base}::/;
            delete $WB2ACE_MAP{$wbclass};
            $WB2ACE_MAP{"${base}::$wbclass"} = $aceclass;
        }

        # map the classes
        my $mp = Module::Pluggable::Object->new(search_path => [$base]);

        my $classmap = $WB2ACE_MAP{class} ||= {};

        foreach my $wbclass ($mp->plugins) {
            Class::MOP::load_class($wbclass); # load the calsses
            # the exceptional cases have already been mapped.
            $classmap->{$wbclass} ||= (split /::/, $wbclass)[-1];
        }
        $WB2ACE_MAP_DONE = 1;
    }

    sub _map_ace2wb { # inverse map of WB2ACE
        # map the classes
        _map_wb2ace() unless $WB2ACE_MAP_DONE;

        my $classmap = $ACE2WB_MAP{class} ||= {};

        while (my ($wb, $ace) = each %{$WB2ACE_MAP{class}}) {
            if (ref $ace eq 'ARRAY') { # multiple Ace to single WB
                foreach my $ace_class (@$ace) {
                    $classmap->{$ace_class} ||= $wb;
                }
            }
            else {              # assume scalar; 1-to-1
                $classmap->{$ace} ||= $wb;
            }
        }
        $ACE2WB_MAP_DONE = 1;
    }

    sub ACE2WB_MAP {
        _map_ace2wb() unless $ACE2WB_MAP_DONE; # manual lazy loading
        return \%ACE2WB_MAP;
    }

    sub WB2ACE_MAP {
        _map_wb2ace() unless $WB2ACE_MAP_DONE; # manual lazy loading
        return \%WB2ACE_MAP;
    }
}

1;
