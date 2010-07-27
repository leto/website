package WormBase::API::Object::Phenotype;

use Moose;
use JSON;

with 'WormBase::API::Role::Object';
extends 'WormBase::API::Object';
 

sub name {
    my $self = shift;
    my $ace  = $self->object;
    my $name = ($ace  =~ /WBPheno.*/) ? $ace->Primary_name : $ace ;
    $name =~ s/_/ /g;
    my $short_name = $self ~~ 'Short_name';
    $name = "$short_name ($name)" if(defined $short_name);
    my $data = { description => 'The name of the phenotype',
		 data        =>  { id    => "$ace",
				   label => "$name",
				   class => $ace->class
		 },
    };
    return $data;
}



############################################################
#
# The Details widget
#
############################################################


sub synonym  {
    
   my $data = { description => 'The synonym name of the phenotype ',
		 	data        => shift ~~ '@Synonym'  ,
    };
   return $data;
}

sub description {
   my $self=shift;
   my $des= $self ~~ 'Description';
  
   my $data = { description => 'The description of the phenotype ',
		 	data        => {      des=>$des ,
					      evidence=>{ flag=> $self->check_empty($des),
							  tag=>"Description",
							}
				      },
    };
   return $data;
}
=pod
sub assay {
    
   my $data = { description => 'The Assay of the phenotype ',
		 	data        => shift ~~ 'Assay'  ,
    };
   return $data;
}

sub remark {
    
   my $data = { description => 'The Remark of the phenotype ',
		 	data        => shift ~~ 'Remark'  ,
    };
   return $data;
}

=cut


sub is_dead {
   my $object = shift->object;
   my $alternate;
   if ($object ->Dead(0)) {
	  $alternate = eval  {$object ->Dead->right };
   } 
   my $data = { description => "The Note of the phenotype when it's retired and replaced by another  ",
		 	data        => {
					     id => $alternate,
					     label => $alternate,
					     class => 'phenotype',
					  } , 
    };
   return $data;
}

 
############################################################
#
# The Ontology Browser widget
# 
############################################################



############################################################
#
# The Related Information widget
#
############################################################
 
sub related_phenotypes {
   my $self = shift;
   my $phenotype = $self->object;
   my $result;
   if ($phenotype->Related_phenotypes(0)) {
	foreach my $tag (qw/Specialisation_of Generalisation_of/) {
	    (my $type = $tag) =~ s/_/ /g;
           my @entries;
	    foreach my $ph ($phenotype->$tag){
	    	push @entries, {id=>$ph, label=>$self->best_phenotype_name($ph), class=>"phenotype"};
	    }
	    $result->{$type}=\@entries;
	}
   }
   my $data = { description => "The related phenotypes ",
		 	data        => $result , 
    };
   return $data;
}

 
sub rnai {
    
    my $data = { description => 'The homology image of the protein',
		 data        => shift->_get_json_data('RNAi'),
    }; 
    return $data;
}

sub variation {
   my ($self,$detail) = @_;
   my $data = { description => "The related variation of the phenotype",
		 	data        => shift->_get_json_data('Variation') , 
    };
   return $data;
}

sub go_term {

   my $data = { description => "The related Go term of the phenotype",
		 	data        => shift->_format_objects('GO_term') , 
    };
   return $data;
}

sub transgene {
  
   my $data = { description => "The related transgene of the phenotype ",
		 	data        => shift->_get_json_data('Transgene') , 
    };
   return $data;
}

sub anatomy_ontology {
    
    my $anatomy_fn = shift ~~ 'Anatomy_function';
    my $anatomy_fn_name = $anatomy_fn->Involved if $anatomy_fn;
    my $anatomy_term = $anatomy_fn_name->Term if $anatomy_fn_name;
    my $anatomy_term_id = $anatomy_term->Name_for_anatomy_term if $anatomy_term;
    my $anatomy_term_name = $anatomy_term_id->Term if $anatomy_term_id;
    return unless $anatomy_term_name;
     
    my $data = { description => "The Anatomy Ontology of the phenotype ",
		 	data        =>  {     id=>$anatomy_term_id,
					      label=>$anatomy_term_id , 
					      class => $anatomy_term_id->class,
					 }
    };
    return $data;
}  
 
############################################################
#
# The Private Methods
#
############################################################

sub _get_json_data {
   my ($self,$tag)=@_;
   my $result;
   my $file = $self->tmp_acedata_dir()."/".$self->object.".$tag.txt";
   if(-s $file) {
       open (F,"<$file") ;
	$result = from_json(<F>);
	close F;
   }
   else{
      $result=$self->_format_objects($tag);
      open (F,">$file") ;
      print F to_json($result);
      close F;
    }
  return $result;
}

sub _format_objects {
    my ($self,$tag) = @_;
    my $phenotype = $self->object;
    my %result;
    my $is_not;
    my @items=$phenotype->$tag;
    my @content_array;
    my @content_array_not;
    foreach (@items){
	my @array;
	my $str=$_;
	if ($tag eq 'RNAi') {
	    my $cds  = $_->Predicted_gene||"";
	    my $gene = $_->Gene;    
	    my $cgc  = eval{$gene->CGC_name} ||"";
	    if($gene){
	      push @array,{     id    => "$gene",
				label => "$cgc",
				class => $gene->class,};
	    }else { push @array, "";}
	    if($cds){
	      push @array,{     id    => "$cds",
				label => "$cds",
				class => $cds->class,
			  };
	    }else { push @array, "";}
	    if(my $sp = $_->Species){
	      $sp =~ /(.*) (.*)/;
	      push @array, {	genus=>$1,
				  species=>$2,
			      };
	    }else { push @array, "";}

	    $is_not = _is_not($_,$phenotype);
	}elsif ($tag eq 'GO_term') {

	    my $joined_evidence;
=pod	need an exmple!!
	    my @evidence = go_evidence_code($_);
	    foreach (@evidence) {
		my ($ty,$evi) = @$_;
		my $tyy = a({-href=>'http://www.geneontology.org/GO.evidence.html',-target=>'_blank'},$ty);
		
		my $evidence = ($ty) ? "($tyy) $evi" : '';
		$joined_evidence = ($joined_evidence) ? ($joined_evidence . br . $evidence) : $evidence;
	    }
=cut
	    my $desc = $_->Term || $_->Definition;
	    $str .= (($desc) ? ": $desc" : '')
		. (($joined_evidence) ? "; $joined_evidence" : '');
	     
	} elsif ($tag eq 'Variation') {
		 $is_not = _is_not($_,$phenotype);
		 my $gene = $_->Gene;
		 if($gene) {
		  push @array,{id    => "$gene",
				  label => $gene->Public_name->name,
				  class => $gene->class,};
		 }else { push @array, "";}
		  $str = $_->Public_name;
		  if(my $sp = $_->Species){
		    $sp =~ /(.*) (.*)/;
		    push @array, {	genus=>$1,
					species=>$2,
				    };
		  }else { push @array, "";}
		 
	} elsif ($tag eq 'Transgene') {
	    #need to deal to Phenotype evidence hash, write more generic code in future/or maybe this already exist
		foreach my $ph ($_->Phenotype){
		    next unless ($ph eq $phenotype);
		    foreach my $tag ($ph->col){
			next unless($tag eq "Caused_by");
			my $gene=$ph->$tag;
			 if($gene) {
			    push @array,{   id    => "$gene",
					    label => $gene->Public_name->name,
					    class => $gene->class,};
			  }else { push @array, "";}
		    }
		}
		my $genotype = $_->Summary;
		push @array,$genotype  if($genotype) ;
		 $is_not = _is_not($_,$phenotype);
	}
	my $hash = {    label=> "$str",
			class => $tag,
			id => "$_", };
 
# 	if(defined $is_not) { $result{content}{$is_not}{$str} = $hash;$count->{$is_not}++;}
# 	else { $result{content}{$str} = $hash;$count++;}
# 	unshift @array, $is_not if(defined $is_not);
	push @array,$hash;
# 	$result{content}{$str} = \@array;
	if($is_not) {
	    push @content_array_not, \@array;
	}else {
	    push @content_array, \@array;
	}
    }
=pod
    if($tag eq 'Variation') {  $result{header} = [('name', 'phenotype observed in this experiment','corresponding gene')];}
    elsif(defined $is_not) {  $result{header} = [('name', 'phenotype observed in this experiment')];}
    else {  $result{header} = [qw/name/];}
=cut  
    if(defined $is_not) {
	$result{0}{"aaData"}=\@content_array;
	$result{1}{"aaData"}=\@content_array_not;
    }else {
      $result{"aaData"}=\@content_array;
    }
    return \%result;
}



sub _is_not {
    my ($obj,$phene) = @_;
    my @phenes = $obj->Phenotype;
    foreach (@phenes)  {
	next unless $_ eq $phene;
	my %keys = map { $_ => 1 } $_->col;
	return 1 if $keys{Not};
	return 0;
    }
}

1;
