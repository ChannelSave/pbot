# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

package PBot::Plugins::Spinach;

use warnings;
use strict;

use feature 'switch';
no if $] >= 5.018, warnings => "experimental::smartmatch";

use Carp ();
use DBI;
use JSON;

sub new {
  Carp::croak("Options to " . __FILE__ . " should be key/value pairs, not hash reference") if ref $_[1] eq 'HASH';
  my ($class, %conf) = @_;
  my $self = bless {}, $class;
  $self->initialize(%conf);
  return $self;
}

sub initialize {
  my ($self, %conf) = @_;
  $self->{pbot} = delete $conf{pbot} // Carp::croak("Missing pbot reference to " . __FILE__);

  $self->{pbot}->{commands}->register(sub { $self->spinach_cmd(@_) }, 'spinach', 0);

  $self->{pbot}->{timer}->register(sub { $self->spinach_timer }, 1, 'spinach timer');
  
  $self->{leaderboard_filename} = $self->{pbot}->{registry}->get_value('general', 'data_dir') . '/spinachlb.sqlite3';
  $self->{questions_filename} = $self->{pbot}->{registry}->get_value('general', 'data_dir') . '/spinachq.json';

  $self->create_database;
  $self->create_states;
  $self->load_questions;

  $self->{channel} = '##spinach';
}

sub unload {
  my $self = shift;
  $self->{pbot}->{commands}->unregister('spinach');
  $self->{pbot}->{timer}->unregister('spinach timer');
}

sub load_questions {
  my $self = shift;

  my $contents = do {
    open my $fh, '<', $self->{questions_filename} or do {
      $self->{pbot}->{ogger}->log("Spinach: Failed to open $self->{questions_filename}: $!\n");
      return;
    };
    local $/;
    <$fh>;
  };

  $self->{questions} = decode_json $contents;
  $self->{categories} = ();

  my $questions;
  foreach my $key (keys %{$self->{questions}}) {
    foreach my $question (@{$self->{questions}->{$key}}) {
      $self->{categories}{$question->{category}}++;
      $questions++;
    }
  }

  my $categories;
  foreach my $category (sort keys %{$self->{categories}}) {
    #$self->{pbot}->{logger}->log("Category [$category]: $self->{categories}{$category}\n");
    $categories++;
  }

  $self->{pbot}->{logger}->log("Spinach: Loaded $questions questions in $categories categories.\n");
}

sub create_database {
  my $self = shift;

  eval {
    $self->{dbh} = DBI->connect("dbi:SQLite:dbname=$self->{leaderboard_filename}", "", "", { RaiseError => 1, PrintError => 0, AutoInactiveDestroy => 1 }) or die $DBI::errstr;

    $self->{dbh}->do(<<SQL);
CREATE TABLE IF NOT EXISTS Leaderboard (
  userid      NUMERIC,
  created_on  NUMERIC,
  wins        NUMERIC,
  highscore   NUMERIC,
  avgscore    NUMERIC
)
SQL

    $self->{dbh}->disconnect;
  };

  $self->{pbot}->{logger}->log("Spinach create database failed: $@") if $@;
}

sub dbi_begin {
  my ($self) = @_;
  eval {
    $self->{dbh} = DBI->connect("dbi:SQLite:dbname=$self->{leaderboard_filename}", "", "", { RaiseError => 1, PrintError => 0, AutoInactiveDestroy => 1 }) or die $DBI::errstr;
  };

  if ($@) {
    $self->{pbot}->{logger}->log("Error opening Spinach database: $@");
    return 0;
  } else {
    return 1;
  }
}

sub dbi_end {
  my ($self) = @_;
  $self->{dbh}->disconnect;
}

sub spinach_cmd {
  my ($self, $from, $nick, $user, $host, $arguments) = @_;
  $arguments = lc $arguments;

  my $usage = "Usage: spinach start|stop|abort|join|exit|ready|kick|choose|lie|truth|score|leaderboard; for more information about a command: spinach help <command>";

  my $command;
  ($command, $arguments) = split / /, $arguments, 2;

  my ($channel, $result);

  given ($command) {
    when ('help') {
      given ($arguments) {
        when ('start') {
          return "Help is coming soon.";
        }

        when ('join') {
          return "Help is coming soon.";
        }

        when ('ready') {
          return "Help is coming soon.";
        }

        when ('exit') {
          return "Help is coming soon.";
        }

        when ('abort') {
          return "Help is coming soon.";
        }

        when ('stop') {
          return "Help is coming soon.";
        }

        when ('kick') {
          return "Help is coming soon.";
        }

        when ('choose') {
          return "Help is coming soon.";
        }

        when ('lie') {
          return "Help is coming soon.";
        }

        when ('truth') {
          return "Help is coming soon.";
        }

        default {
          if (length $arguments) {
            return "Spinach has no such command '$arguments'. I can't help you with that.";
          } else {
            return "Usage: spinach help <command>";
          }
        }
      }
    }

    when ('load') {
      my $admin = $self->{pbot}->{admins}->loggedin($self->{channel}, "$nick!$user\@$host");

      if (not $admin or $admin->{level} < 90) {
        return "$nick: Sorry, only very powerful admins may reload the questions.";
      }

      $self->load_questions;
    }

    when ('start') {
      if ($self->{current_state} eq 'nogame') {
        $self->{current_state} = 'getplayers';
        return "/msg $self->{channel} Starting Spinach.";
      } else {
        return "Spinach is already started.";
      }
    }

    when ('join') {
      if ($self->{current_state} eq 'nogame') {
        return "There is no game started. Use `start` to begin a new game.";
      } elsif ($self->{current_state} ne 'getplayers') {
        return "There is a game in progress. You may join after the game is over.";
      }

      my $id = $self->{pbot}->{messagehistory}->{database}->get_message_account($nick, $user, $host);

      foreach my $player (@{$self->{state_data}->{players}}) {
        if ($player->{id} == $id) {
          return "$nick: You have already joined this game.";
        }
      }
      
      my $player = { id => $id, name => $nick, score => 0, ready => 0, missedinputs => 0 };
      push @{$self->{state_data}->{players}}, $player;
      return "/msg $self->{channel} $nick has joined the game!";
    }

    when ('ready') {
      if ($self->{current_state} eq 'nogame') {
        return "There is no game started. Use `start` to begin a new game.";
      } elsif ($self->{current_state} ne 'getplayers') {
        return "There is a game in progress. You may join after the game is over.";
      }

      my $id = $self->{pbot}->{messagehistory}->{database}->get_message_account($nick, $user, $host);

      foreach my $player (@{$self->{state_data}->{players}}) {
        if ($player->{id} == $id) {
          $player->{ready} = 1;
          return "/msg $self->{channel} $nick is ready!";
        }
      }

      return "$nick: You haven't joined this game yet.";
    }

    when ('exit') {
      my $id = $self->{pbot}->{messagehistory}->{database}->get_message_account($nick, $user, $host);
      my $removed = 0;

      for (my $i = 0; $i < @{$self->{state_data}->{players}}; $i++) {
        if ($self->{state_data}->{players}->[$i]->{id} == $id) {
          splice @{$self->{state_data}->{players}}, $i--, 1;
          $removed = 1;
        }
      }

      if ($removed) {
        return "/msg $self->{channel} $nick has left the game!";
      } else {
        return "$nick: But you are not even playing the game.";
      }
    }

    when ('abort') {
      if (not $self->{pbot}->{admins}->loggedin($self->{channel}, "$nick!$user\@$host")) {
        return "$nick: Sorry, only admins may abort the game.";
      }

      $self->{current_state} = 'gameover';
      return "/msg $self->{channel} $nick: The game has been aborted.";
    }

    when ('stop') {
      if ($self->{current_state} ne 'getplayers') {
        return "This command can only be used during the 'Waiting for players' stage. To stop a game in progress, use the `abort` command.";
      }

      $self->{current_state} = 'nogame';
      $self->{state_data} = { players => [] };
      return "/msg $self->{channel} $nick: The game has been stopped.";
    }

    when ('kick') {
      if (not $self->{pbot}->{admins}->loggedin($self->{channel}, "$nick!$user\@$host")) {
        return "$nick: Sorry, only admins may kick people from the game.";
      }

      if (not length $arguments) {
        return "Usage: spinach kick <nick>";
      }

      my $removed = 0;

      for (my $i = 0; $i < @{$self->{state_data}->{players}}; $i++) {
        if (lc $self->{state_data}->{players}->[$i]->{name} eq $arguments) {
          splice @{$self->{state_data}->{players}}, $i--, 1;
          $removed = 1;
        }
      }

      if ($removed) {
        return "/msg $self->{channel} $nick: $arguments has been kicked from the game.";
      } else {
        return "$nick: $arguments isn't even in the game.";
      }
    }

    when ('choose') {
      if ($self->{current_state} !~ /choosecategory$/) {
        return "$nick: It is not time to choose a category.";
      }

      if (not length $arguments) {
        return "Usage: spinach choose <integer>";
      }

      my $id = $self->{pbot}->{messagehistory}->{database}->get_message_account($nick, $user, $host);

      if ($id != $self->{state_data}->{players}->[$self->{state_data}->{current_player}]->{id}) {
        return "$nick: It is not your turn to choose a category.";
      } 
      
      if ($arguments !~ /^[0-9]+$/) {
        return "$nick: Please choose a category number. $self->{state_data}->{categories_text}";
      }

      $arguments--;

      if ($arguments < 0 or $arguments >= @{$self->{state_data}->{category_options}}) {
        return "$nick: Choice out of range. Please choose a valid category. $self->{state_data}->{categories_text}";
      }

      $self->{state_data}->{current_category} = $self->{state_data}->{category_options}->[$arguments];
      return "/msg $self->{channel} $nick has chosen $self->{state_data}->{current_category}!";
    }

    when ('lie') {
      if ($self->{current_state} !~ /getlies$/) {
        return "$nick: It is not time to submit a lie!";
      }

      if (not length $arguments) {
        return "Usage: spinach lie <text>";
      }

      my $id = $self->{pbot}->{messagehistory}->{database}->get_message_account($nick, $user, $host);

      my $player;
      foreach my $i (@{$self->{state_data}->{players}}) {
        if ($i->{id} == $id) {
          $player = $i;
          last;
        }
      }

      if (not $player) {
        return "$nick: You are not playing in this game. Please wait until the next game.";
      }

      my $found_truth = 0;

      if ($arguments eq lc $self->{state_data}->{current_question}->{answer}) {
        $found_truth = 1;
      }

      foreach my $alt (@{$self->{state_data}->{current_question}->{alternateSpellings}}) {
        if ($arguments eq lc $alt) {
          $found_truth = 1;
          last;
        }
      }

      if ($found_truth) {
        return "$nick: You found the truth! Please submit a different lie.";
      }

      $player->{lie} = uc $arguments;

      return "/msg $self->{channel} $nick has submitted a lie!";
    }

    when ('truth') {
      if ($self->{current_state} !~ /findtruth$/) {
        return "$nick: It is not time to find the truth!";
      }

      if (not length $arguments) {
        return "Usage: spinach truth <integer>";
      }

      my $id = $self->{pbot}->{messagehistory}->{database}->get_message_account($nick, $user, $host);

      my $player;
      foreach my $i (@{$self->{state_data}->{players}}) {
        if ($i->{id} == $id) {
          $player = $i;
          last;
        }
      }

      if (not $player) {
        return "$nick: You are not playing in this game. Please wait until the next game.";
      }

      if ($arguments !~ /^[0-9]+$/) {
        return "$nick: Please select a truth number. $self->{state_data}->{current_choices_text}";
      }

      $arguments--;

      if ($arguments < 0 or $arguments >= @{$self->{state_data}->{current_choices}}) {
        return "$nick: Selection out of range. Please select a valid truth: $self->{state_data}->{current_choices_text}";
      }

      $player->{truth} = uc $self->{state_data}->{current_choices}->[$arguments];

      if ($player->{truth} eq $player->{lie}) {
        delete $player->{truth};
        return "$nick: You cannot select your own lie!";
      }

      return "/msg $self->{channel} $nick has selected a truth!";
    }

    default {
      return $usage;
    }
  }

  return $result;
}

sub spinach_timer {
  my $self = shift;
  $self->run_one_state;
}

sub run_one_state {
  my $self = shift;

  $self->{state_data}->{ticks}++;

  my $current_state = $self->{current_state};
  my $state_data = $self->{state_data};

  if (not defined $current_state) {
    $self->{pbot}->{logger}->log("Spinach state broke.");
    return;
  }

  $state_data = $self->{states}{$current_state}{sub}($state_data);

  $self->{current_state} = $self->{states}{$current_state}{trans}{$state_data->{result}};
  $self->{state_data} = $state_data;
}

sub create_states {
  my $self = shift;

  $self->{pbot}->{logger}->log("Spinach: Creating game state machine\n");

  $self->{current_state} = 'nogame';
  $self->{state_data} = { players => [] };

  $self->{states}{'nogame'}{sub} = sub { $self->nogame(@_) };
  $self->{states}{'nogame'}{trans}{start} = 'getplayers';
  $self->{states}{'nogame'}{trans}{nogame} = 'nogame';

  $self->{states}{'getplayers'}{sub} = sub { $self->getplayers(@_) };
  $self->{states}{'getplayers'}{trans}{wait} = 'getplayers';
  $self->{states}{'getplayers'}{trans}{allready} = 'round1';

  $self->{states}{'round1'}{sub} = sub { $self->round1(@_) };
  $self->{states}{'round1'}{trans}{next} = 'round1q1';

  $self->{states}{'round1q1'}{sub} = sub { $self->round1q1(@_) };
  $self->{states}{'round1q1'}{trans}{next} = 'r1q1choosecategory';
  $self->{states}{'r1q1choosecategory'}{sub} = sub { $self->r1q1choosecategory(@_) };
  $self->{states}{'r1q1choosecategory'}{trans}{wait} = 'r1q1choosecategory';
  $self->{states}{'r1q1choosecategory'}{trans}{next} = 'r1q1showquestion';
  $self->{states}{'r1q1showquestion'}{sub} = sub { $self->r1q1showquestion(@_) };
  $self->{states}{'r1q1showquestion'}{trans}{next} = 'r1q1getlies';
  $self->{states}{'r1q1getlies'}{sub} = sub { $self->r1q1getlies(@_) };
  $self->{states}{'r1q1getlies'}{trans}{wait} = 'r1q1getlies';
  $self->{states}{'r1q1getlies'}{trans}{next} = 'r1q1findtruth';
  $self->{states}{'r1q1findtruth'}{sub} = sub { $self->r1q1findtruth(@_) };
  $self->{states}{'r1q1findtruth'}{trans}{wait} = 'r1q1findtruth';
  $self->{states}{'r1q1findtruth'}{trans}{next} = 'r1q1showlies';
  $self->{states}{'r1q1showlies'}{sub} = sub { $self->r1q1showlies(@_) };
  $self->{states}{'r1q1showlies'}{trans}{wait} = 'r1q1showlies';
  $self->{states}{'r1q1showlies'}{trans}{next} = 'r1q1showtruth';
  $self->{states}{'r1q1showtruth'}{sub} = sub { $self->r1q1showtruth(@_) };
  $self->{states}{'r1q1showtruth'}{trans}{next} = 'r1q1showscore';
  $self->{states}{'r1q1showscore'}{sub} = sub { $self->r1q1showscore(@_) };
  $self->{states}{'r1q1showscore'}{trans}{next} = 'round1q2';

  $self->{states}{'round1q2'}{sub} = sub { $self->round1q2(@_) };
  $self->{states}{'round1q2'}{trans}{next} = 'r1q2choosecategory';
  $self->{states}{'r1q2choosecategory'}{sub} = sub { $self->r1q2choosecategory(@_) };
  $self->{states}{'r1q2choosecategory'}{trans}{wait} = 'r1q2choosecategory';
  $self->{states}{'r1q2choosecategory'}{trans}{next} = 'r1q2showquestion';
  $self->{states}{'r1q2showquestion'}{sub} = sub { $self->r1q2showquestion(@_) };
  $self->{states}{'r1q2showquestion'}{trans}{next} = 'r1q2getlies';
  $self->{states}{'r1q2getlies'}{sub} = sub { $self->r1q2getlies(@_) };
  $self->{states}{'r1q2getlies'}{trans}{wait} = 'r1q2getlies';
  $self->{states}{'r1q2getlies'}{trans}{next} = 'r1q2findtruth';
  $self->{states}{'r1q2findtruth'}{sub} = sub { $self->r1q2findtruth(@_) };
  $self->{states}{'r1q2findtruth'}{trans}{wait} = 'r1q2findtruth';
  $self->{states}{'r1q2findtruth'}{trans}{next} = 'r1q2showlies';
  $self->{states}{'r1q2showlies'}{sub} = sub { $self->r1q2showlies(@_) };
  $self->{states}{'r1q2showlies'}{trans}{wait} = 'r1q2showlies';
  $self->{states}{'r1q2showlies'}{trans}{next} = 'r1q2showtruth';
  $self->{states}{'r1q2showtruth'}{sub} = sub { $self->r1q2showtruth(@_) };
  $self->{states}{'r1q2showtruth'}{trans}{next} = 'r1q2showscore';
  $self->{states}{'r1q2showscore'}{sub} = sub { $self->r1q2showscore(@_) };
  $self->{states}{'r1q2showscore'}{trans}{next} = 'round1q3';

  $self->{states}{'round1q3'}{sub} = sub { $self->round1q3(@_) };
  $self->{states}{'round1q3'}{trans}{next} = 'r1q3choosecategory';
  $self->{states}{'r1q3choosecategory'}{sub} = sub { $self->r1q3choosecategory(@_) };
  $self->{states}{'r1q3choosecategory'}{trans}{wait} = 'r1q3choosecategory';
  $self->{states}{'r1q3choosecategory'}{trans}{next} = 'r1q3showquestion';
  $self->{states}{'r1q3showquestion'}{sub} = sub { $self->r1q3showquestion(@_) };
  $self->{states}{'r1q3showquestion'}{trans}{next} = 'r1q3getlies';
  $self->{states}{'r1q3getlies'}{sub} = sub { $self->r1q3getlies(@_) };
  $self->{states}{'r1q3getlies'}{trans}{wait} = 'r1q3getlies';
  $self->{states}{'r1q3getlies'}{trans}{next} = 'r1q3findtruth';
  $self->{states}{'r1q3findtruth'}{sub} = sub { $self->r1q3findtruth(@_) };
  $self->{states}{'r1q3findtruth'}{trans}{wait} = 'r1q3findtruth';
  $self->{states}{'r1q3findtruth'}{trans}{next} = 'r1q3showlies';
  $self->{states}{'r1q3showlies'}{sub} = sub { $self->r1q3showlies(@_) };
  $self->{states}{'r1q3showlies'}{trans}{wait} = 'r1q3showlies';
  $self->{states}{'r1q3showlies'}{trans}{next} = 'r1q3showtruth';
  $self->{states}{'r1q3showtruth'}{sub} = sub { $self->r1q3showtruth(@_) };
  $self->{states}{'r1q3showtruth'}{trans}{next} = 'r1q3showscore';
  $self->{states}{'r1q3showscore'}{sub} = sub { $self->r1q3showscore(@_) };
  $self->{states}{'r1q3showscore'}{trans}{next} = 'round2';

  $self->{states}{'round2'}{sub} = sub { $self->round2(@_) };
  $self->{states}{'round2'}{trans}{next} = 'round2q1';

  $self->{states}{'round2q1'}{sub} = sub { $self->round2q1(@_) };
  $self->{states}{'round2q1'}{trans}{next} = 'r2q1choosecategory';
  $self->{states}{'r2q1choosecategory'}{sub} = sub { $self->r2q1choosecategory(@_) };
  $self->{states}{'r2q1choosecategory'}{trans}{wait} = 'r2q1choosecategory';
  $self->{states}{'r2q1choosecategory'}{trans}{next} = 'r2q1showquestion';
  $self->{states}{'r2q1showquestion'}{sub} = sub { $self->r2q1showquestion(@_) };
  $self->{states}{'r2q1showquestion'}{trans}{next} = 'r2q1getlies';
  $self->{states}{'r2q1getlies'}{sub} = sub { $self->r2q1getlies(@_) };
  $self->{states}{'r2q1getlies'}{trans}{wait} = 'r2q1getlies';
  $self->{states}{'r2q1getlies'}{trans}{next} = 'r2q1findtruth';
  $self->{states}{'r2q1findtruth'}{sub} = sub { $self->r2q1findtruth(@_) };
  $self->{states}{'r2q1findtruth'}{trans}{wait} = 'r2q1findtruth';
  $self->{states}{'r2q1findtruth'}{trans}{next} = 'r2q1showlies';
  $self->{states}{'r2q1showlies'}{sub} = sub { $self->r2q1showlies(@_) };
  $self->{states}{'r2q1showlies'}{trans}{wait} = 'r2q1showlies';
  $self->{states}{'r2q1showlies'}{trans}{next} = 'r2q1showtruth';
  $self->{states}{'r2q1showtruth'}{sub} = sub { $self->r2q1showtruth(@_) };
  $self->{states}{'r2q1showtruth'}{trans}{next} = 'r2q1showscore';
  $self->{states}{'r2q1showscore'}{sub} = sub { $self->r2q1showscore(@_) };
  $self->{states}{'r2q1showscore'}{trans}{next} = 'round2q2';

  $self->{states}{'round2q2'}{sub} = sub { $self->round2q2(@_) };
  $self->{states}{'round2q2'}{trans}{next} = 'r2q2choosecategory';
  $self->{states}{'r2q2choosecategory'}{sub} = sub { $self->r2q2choosecategory(@_) };
  $self->{states}{'r2q2choosecategory'}{trans}{wait} = 'r2q2choosecategory';
  $self->{states}{'r2q2choosecategory'}{trans}{next} = 'r2q2showquestion';
  $self->{states}{'r2q2showquestion'}{sub} = sub { $self->r2q2showquestion(@_) };
  $self->{states}{'r2q2showquestion'}{trans}{next} = 'r2q2getlies';
  $self->{states}{'r2q2getlies'}{sub} = sub { $self->r2q2getlies(@_) };
  $self->{states}{'r2q2getlies'}{trans}{wait} = 'r2q2getlies';
  $self->{states}{'r2q2getlies'}{trans}{next} = 'r2q2findtruth';
  $self->{states}{'r2q2findtruth'}{sub} = sub { $self->r2q2findtruth(@_) };
  $self->{states}{'r2q2findtruth'}{trans}{wait} = 'r2q2findtruth';
  $self->{states}{'r2q2findtruth'}{trans}{next} = 'r2q2showlies';
  $self->{states}{'r2q2showlies'}{sub} = sub { $self->r2q2showlies(@_) };
  $self->{states}{'r2q2showlies'}{trans}{wait} = 'r2q2showlies';
  $self->{states}{'r2q2showlies'}{trans}{next} = 'r2q2showtruth';
  $self->{states}{'r2q2showtruth'}{sub} = sub { $self->r2q2showtruth(@_) };
  $self->{states}{'r2q2showtruth'}{trans}{next} = 'r2q2showscore';
  $self->{states}{'r2q2showscore'}{sub} = sub { $self->r2q2showscore(@_) };
  $self->{states}{'r2q2showscore'}{trans}{next} = 'round2q3';

  $self->{states}{'round2q3'}{sub} = sub { $self->round2q3(@_) };
  $self->{states}{'round2q3'}{trans}{next} = 'r2q3choosecategory';
  $self->{states}{'r2q3choosecategory'}{sub} = sub { $self->r2q3choosecategory(@_) };
  $self->{states}{'r2q3choosecategory'}{trans}{wait} = 'r2q3choosecategory';
  $self->{states}{'r2q3choosecategory'}{trans}{next} = 'r2q3showquestion';
  $self->{states}{'r2q3showquestion'}{sub} = sub { $self->r2q3showquestion(@_) };
  $self->{states}{'r2q3showquestion'}{trans}{next} = 'r2q3getlies';
  $self->{states}{'r2q3getlies'}{sub} = sub { $self->r2q3getlies(@_) };
  $self->{states}{'r2q3getlies'}{trans}{wait} = 'r2q3getlies';
  $self->{states}{'r2q3getlies'}{trans}{next} = 'r2q3findtruth';
  $self->{states}{'r2q3findtruth'}{sub} = sub { $self->r2q3findtruth(@_) };
  $self->{states}{'r2q3findtruth'}{trans}{wait} = 'r2q3findtruth';
  $self->{states}{'r2q3findtruth'}{trans}{next} = 'r2q3showlies';
  $self->{states}{'r2q3showlies'}{sub} = sub { $self->r2q3showlies(@_) };
  $self->{states}{'r2q3showlies'}{trans}{wait} = 'r2q3showlies';
  $self->{states}{'r2q3showlies'}{trans}{next} = 'r2q3showtruth';
  $self->{states}{'r2q3showtruth'}{sub} = sub { $self->r2q3showtruth(@_) };
  $self->{states}{'r2q3showtruth'}{trans}{next} = 'r2q3showscore';
  $self->{states}{'r2q3showscore'}{sub} = sub { $self->r2q3showscore(@_) };
  $self->{states}{'r2q3showscore'}{trans}{next} = 'round3';

  $self->{states}{'round3'}{sub} = sub { $self->round3(@_) };
  $self->{states}{'round3'}{trans}{next} = 'round3q1';

  $self->{states}{'round3q1'}{sub} = sub { $self->round3q1(@_) };
  $self->{states}{'round3q1'}{trans}{next} = 'r3q1choosecategory';
  $self->{states}{'r3q1choosecategory'}{sub} = sub { $self->r3q1choosecategory(@_) };
  $self->{states}{'r3q1choosecategory'}{trans}{wait} = 'r3q1choosecategory';
  $self->{states}{'r3q1choosecategory'}{trans}{next} = 'r3q1showquestion';
  $self->{states}{'r3q1showquestion'}{sub} = sub { $self->r3q1showquestion(@_) };
  $self->{states}{'r3q1showquestion'}{trans}{next} = 'r3q1getlies';
  $self->{states}{'r3q1getlies'}{sub} = sub { $self->r3q1getlies(@_) };
  $self->{states}{'r3q1getlies'}{trans}{wait} = 'r3q1getlies';
  $self->{states}{'r3q1getlies'}{trans}{next} = 'r3q1findtruth';
  $self->{states}{'r3q1findtruth'}{sub} = sub { $self->r3q1findtruth(@_) };
  $self->{states}{'r3q1findtruth'}{trans}{wait} = 'r3q1findtruth';
  $self->{states}{'r3q1findtruth'}{trans}{next} = 'r3q1showlies';
  $self->{states}{'r3q1showlies'}{sub} = sub { $self->r3q1showlies(@_) };
  $self->{states}{'r3q1showlies'}{trans}{wait} = 'r3q1showlies';
  $self->{states}{'r3q1showlies'}{trans}{next} = 'r3q1showtruth';
  $self->{states}{'r3q1showtruth'}{sub} = sub { $self->r3q1showtruth(@_) };
  $self->{states}{'r3q1showtruth'}{trans}{next} = 'r3q1showscore';
  $self->{states}{'r3q1showscore'}{sub} = sub { $self->r3q1showscore(@_) };
  $self->{states}{'r3q1showscore'}{trans}{next} = 'round3q2';

  $self->{states}{'round3q2'}{sub} = sub { $self->round3q2(@_) };
  $self->{states}{'round3q2'}{trans}{next} = 'r3q2choosecategory';
  $self->{states}{'r3q2choosecategory'}{sub} = sub { $self->r3q2choosecategory(@_) };
  $self->{states}{'r3q2choosecategory'}{trans}{wait} = 'r3q2choosecategory';
  $self->{states}{'r3q2choosecategory'}{trans}{next} = 'r3q2showquestion';
  $self->{states}{'r3q2showquestion'}{sub} = sub { $self->r3q2showquestion(@_) };
  $self->{states}{'r3q2showquestion'}{trans}{next} = 'r3q2getlies';
  $self->{states}{'r3q2getlies'}{sub} = sub { $self->r3q2getlies(@_) };
  $self->{states}{'r3q2getlies'}{trans}{wait} = 'r3q2getlies';
  $self->{states}{'r3q2getlies'}{trans}{next} = 'r3q2findtruth';
  $self->{states}{'r3q2findtruth'}{sub} = sub { $self->r3q2findtruth(@_) };
  $self->{states}{'r3q2findtruth'}{trans}{wait} = 'r3q2findtruth';
  $self->{states}{'r3q2findtruth'}{trans}{next} = 'r3q2showlies';
  $self->{states}{'r3q2showlies'}{sub} = sub { $self->r3q2showlies(@_) };
  $self->{states}{'r3q2showlies'}{trans}{wait} = 'r3q2showlies';
  $self->{states}{'r3q2showlies'}{trans}{next} = 'r3q2showtruth';
  $self->{states}{'r3q2showtruth'}{sub} = sub { $self->r3q2showtruth(@_) };
  $self->{states}{'r3q2showtruth'}{trans}{next} = 'r3q2showscore';
  $self->{states}{'r3q2showscore'}{sub} = sub { $self->r3q2showscore(@_) };
  $self->{states}{'r3q2showscore'}{trans}{next} = 'round3q3';

  $self->{states}{'round3q3'}{sub} = sub { $self->round3q3(@_) };
  $self->{states}{'round3q3'}{trans}{next} = 'r3q3choosecategory';
  $self->{states}{'r3q3choosecategory'}{sub} = sub { $self->r3q3choosecategory(@_) };
  $self->{states}{'r3q3choosecategory'}{trans}{wait} = 'r3q3choosecategory';
  $self->{states}{'r3q3choosecategory'}{trans}{next} = 'r3q3showquestion';
  $self->{states}{'r3q3showquestion'}{sub} = sub { $self->r3q3showquestion(@_) };
  $self->{states}{'r3q3showquestion'}{trans}{next} = 'r3q3getlies';
  $self->{states}{'r3q3getlies'}{sub} = sub { $self->r3q3getlies(@_) };
  $self->{states}{'r3q3getlies'}{trans}{wait} = 'r3q3getlies';
  $self->{states}{'r3q3getlies'}{trans}{next} = 'r3q3findtruth';
  $self->{states}{'r3q3findtruth'}{sub} = sub { $self->r3q3findtruth(@_) };
  $self->{states}{'r3q3findtruth'}{trans}{wait} = 'r3q3findtruth';
  $self->{states}{'r3q3findtruth'}{trans}{next} = 'r3q3showlies';
  $self->{states}{'r3q3showlies'}{sub} = sub { $self->r3q3showlies(@_) };
  $self->{states}{'r3q3showlies'}{trans}{wait} = 'r3q3showlies';
  $self->{states}{'r3q3showlies'}{trans}{next} = 'r3q3showtruth';
  $self->{states}{'r3q3showtruth'}{sub} = sub { $self->r3q3showtruth(@_) };
  $self->{states}{'r3q3showtruth'}{trans}{next} = 'r3q3showscore';
  $self->{states}{'r3q3showscore'}{sub} = sub { $self->r3q3showscore(@_) };
  $self->{states}{'r3q3showscore'}{trans}{next} = 'round4';

  $self->{states}{'round4'}{sub} = sub { $self->round4(@_) };
  $self->{states}{'round4'}{trans}{next} = 'round4q1';

  $self->{states}{'round4q1'}{sub} = sub { $self->round4q1(@_) };
  $self->{states}{'round4q1'}{trans}{next} = 'r4q1choosecategory';
  $self->{states}{'r4q1choosecategory'}{sub} = sub { $self->r4q1choosecategory(@_) };
  $self->{states}{'r4q1choosecategory'}{trans}{wait} = 'r4q1choosecategory';
  $self->{states}{'r4q1choosecategory'}{trans}{next} = 'r4q1showquestion';
  $self->{states}{'r4q1showquestion'}{sub} = sub { $self->r4q1showquestion(@_) };
  $self->{states}{'r4q1showquestion'}{trans}{next} = 'r4q1getlies';
  $self->{states}{'r4q1getlies'}{sub} = sub { $self->r4q1getlies(@_) };
  $self->{states}{'r4q1getlies'}{trans}{wait} = 'r4q1getlies';
  $self->{states}{'r4q1getlies'}{trans}{next} = 'r4q1findtruth';
  $self->{states}{'r4q1findtruth'}{sub} = sub { $self->r4q1findtruth(@_) };
  $self->{states}{'r4q1findtruth'}{trans}{wait} = 'r4q1findtruth';
  $self->{states}{'r4q1findtruth'}{trans}{next} = 'r4q1showlies';
  $self->{states}{'r4q1showlies'}{sub} = sub { $self->r4q1showlies(@_) };
  $self->{states}{'r4q1showlies'}{trans}{wait} = 'r4q1showlies';
  $self->{states}{'r4q1showlies'}{trans}{next} = 'r4q1showtruth';
  $self->{states}{'r4q1showtruth'}{sub} = sub { $self->r4q1showtruth(@_) };
  $self->{states}{'r4q1showtruth'}{trans}{next} = 'r4q1showscore';
  $self->{states}{'r4q1showscore'}{sub} = sub { $self->r4q1showscore(@_) };
  $self->{states}{'r4q1showscore'}{trans}{next} = 'gameover';

  $self->{states}{'gameover'}{sub} = sub { $self->gameover(@_) };
  $self->{states}{'gameover'}{trans}{next} = 'getplayers';
}

# generic state subroutines

sub choosecategory {
  my ($self, $state) = @_;

  if ($state->{init}) {
    delete $state->{current_category};
    $state->{current_player}++;

    if ($state->{current_player} >= @{$state->{players}}) {
      $state->{current_player} = 0;
    }

    my @choices;
    my @categories = keys %{$self->{categories}};

    my $no_infinite_loops = 0;
    while (1) {
      my $cat = $categories[rand @categories];

      $self->{pbot}->{logger}->log("random cat: [$cat]\n");

      if (not grep { $_ eq $cat } @choices) {
        push @choices, $cat;
      }

      last if @choices == 5;
      last if ++$no_infinite_loops > 20;
    }

    $state->{categories_text} = '';
    my $i = 1;
    my $comma = '';
    foreach my $choice (@choices) {
      $state->{categories_text} .= "$comma$i) $choice";
      $i++;
      $comma = "; ";
    }

    $state->{category_options} = \@choices;
    delete $state->{init};
  }

  if ($state->{ticks} % 15 == 0) {
    if (++$state->{counter} >= 8) {
      $state->{players}->[$state->{current_player}]->{missedinputs}++;
      my $name = $state->{players}->[$state->{current_player}]->{name};
      my $category = $state->{category_options}->[rand @{$state->{category_options}}];
      $self->{pbot}->{conn}->privmsg($self->{channel}, "$name took too long to choose. Randomly choosing: $category!");
      $state->{current_category} = $category;
      return 'next';
    }

    my $name = $state->{players}->[$state->{current_player}]->{name};
    $self->{pbot}->{conn}->privmsg($self->{channel}, "$name: Choose a category from: $state->{categories_text}");
    return 'wait';
  }

  if (exists $state->{current_category}) {
    return 'next';
  } else {
    return 'wait';
  }
}

sub getnewquestion {
  my ($self, $state) = @_;
  my @questions = grep { $_->{category} eq $state->{current_category} } @{$self->{questions}->{normal}};
  $state->{current_question} = $questions[rand @questions];

  foreach my $player (@{$state->{players}}) {
    delete $player->{lie};
    delete $player->{truth};
    delete $player->{deceived};
  }
}

sub showquestion {
  my ($self, $state) = @_;

  if (exists $state->{current_question}) {
    $self->{pbot}->{conn}->privmsg($self->{channel}, "Current question: $state->{current_question}->{question}");
  } else {
    $self->{pbot}->{conn}->privmsg($self->{channel}, "There is no current question.");
  }
}

sub getlies {
  my ($self, $state) = @_;

  if ($state->{ticks} % 15 == 0) {
    if (++$state->{counter} >= 8) {
      my @missedinputs;
      foreach my $player (@{$state->{players}}) {
        if (not exists $player->{lie}) {
          push @missedinputs, $player->{name};
          $player->{missedinputs}++;
        }
      }

      if (@missedinputs) {
        my $missed = join ', ', @missedinputs;
        $self->{pbot}->{conn}->privmsg($self->{channel}, "$missed failed to submit a lie in time!");
      }
      return 'next';
    }
  }

  my @nolies;
  foreach my $player (@{$state->{players}}) {
    if (not exists $player->{lie}) {
      push @nolies, $player->{name};
    }
  }

  return 'next' if not @nolies;

  if ($state->{ticks} % 15 == 0) {
    my $players = join ', ', @nolies;
    $self->{pbot}->{conn}->privmsg($self->{channel}, "$players: Submit your lie now via /msg candide spinach lie <lie>!");
  }

  return 'wait';
}

sub findtruth {
  my ($self, $state) = @_;

  if ($state->{ticks} % 15 == 0) {
    if (++$state->{counter} >= 8) {
      my @missedinputs;
      foreach my $player (@{$state->{players}}) {
        if (not exists $player->{truth}) {
          push @missedinputs, $player->{name};
          $player->{missedinputs}++;
        }
      }

      if (@missedinputs) {
        my $missed = join ', ', @missedinputs;
        $self->{pbot}->{conn}->privmsg($self->{channel}, "$missed failed to find the truth in time!");
      }
      return 'next';
    }
  }

  my @notruth;
  foreach my $player (@{$state->{players}}) {
    if (not exists $player->{truth}) {
      push @notruth, $player->{name};
    }
  }

  return 'next' if not @notruth;

  if ($state->{ticks} % 15 == 0) {
    if ($state->{init}) {
      delete $state->{init};

      my @choices;
      my @suggestions = @{$state->{current_question}->{suggestions}};
      my @lies;

      foreach my $player (@{$state->{players}}) {
        if ($player->{lie}) {
          if (not grep { $_ eq $player->{lie} } @lies) {
            push @lies, uc $player->{lie};
          }
        }
      }

      while (1) {
        my $limit = @{$state->{players}} < 5 ? 5 : @{$state->{players}};
        last if @choices >= $limit;

        if (@lies) {
          my $random = rand @lies;
          push @choices, $lies[$random];
          splice @lies, $random, 1;
          next;
        }

        if (@suggestions) {
          my $random = rand @suggestions;
          push @choices, uc $suggestions[$random];
          splice @suggestions, $random, 1;
          next;
        }

        last;
      }

      splice @choices, rand @choices, 0, uc $state->{current_question}->{answer};
      $state->{correct_answer} = uc $state->{current_question}->{answer};

      my $i = 0;
      my $comma = '';
      my $text = '';
      foreach my $choice (@choices) {
        ++$i;
        $text .= "$comma$i) $choice";
        $comma = '; ';
      }

      $state->{current_choices_text} = $text;
      $state->{current_choices} = \@choices;
    }

    my $players = join ', ', @notruth;
    $self->{pbot}->{conn}->privmsg($self->{channel}, "$players: Find the truth now via /msg candide truth <selection>! $state->{current_choices_text}");
  }

  return 'wait';
}

sub showlies {
  my ($self, $state) = @_;

  my @liars;
  my $player;

  if ($state->{ticks} % 7 == 0) {
    while ($state->{current_lie_player} < @{$state->{players}}) {
      $player = $state->{players}->[$state->{current_lie_player}];
      $state->{current_lie_player}++;
      next if not exists $player->{truth};

      foreach my $liar (@{$state->{players}}) {
        next if $liar->{id} == $player->{id};
        next if not exists $liar->{lie};

        if ($liar->{lie} eq $player->{truth}) {
          push @liars, $liar;
        }
      }

      last if @liars;

      if ($player->{truth} ne $state->{correct_answer}) {
        $player->{score} -= $state->{lie_points};
        $self->{pbot}->{conn}->privmsg($self->{channel}, "$player->{name} fell for my lie: \"$player->{truth}\". -$state->{lie_points} points!");
        $player->{deceived} = 1;
      }
    }

    if (@liars) {
      my $liars_text = '';
      my $liars_no_apostrophe = '';
      my $lie = $player->{truth};
      my $gains = @liars == 1 ? 'gains' : 'gain';
      my $comma = '';

      foreach my $liar (@liars) {
        $liars_text .= "$comma$liar->{name}'s";
        $liars_no_apostrophe .= "$comma$liar->{name}";
        $comma = ', ';
        $liar->{score} += $state->{lie_points};
      }

      $self->{pbot}->{conn}->privmsg($self->{channel}, "$player->{name} fell for $liars_text lie: \"$lie\". $liars_no_apostrophe $gains +$state->{lie_points} points!");
      $player->{deceived} = 1;
    }

    return 'next' if $state->{current_lie_player} >= @{$state->{players}};
    return 'wait';
  }

  return 'wait';
}

sub showtruth {
  my ($self, $state) = @_;

  my $players;
  my $comma = '';
  my $count = 0;
  foreach my $player (@{$state->{players}}) {
    next if exists $player->{deceived};
    if (exists $player->{truth} and $player->{truth} eq $state->{correct_answer}) {
      $count++;
      $players .= "$comma$player->{name}";
      $comma = ', ';
      $player->{score} += $state->{truth_points};
    }
  }

  if ($count) {
    $self->{pbot}->{conn}->privmsg($self->{channel}, "$players got the correct answer: \"$state->{correct_answer}\". +$state->{truth_points} points!");
  }

  my $text = $count == 0 ? 'Nobody found the truth! Revealing lies: ' : 'Revealing lies! ';
  $comma = '';
  foreach my $player (@{$state->{players}}) {
    next if not exists $player->{lie};
    $text .= "$comma$player->{name}: $player->{lie}";
    $comma = '; ';
  }

  $self->{pbot}->{conn}->privmsg($self->{channel}, $text);

  return 'next';
}

sub showscore {
  my ($self, $state) = @_;

  my $text = '';
  my $comma = '';
  foreach my $player (sort { $b->{score} <=> $a->{score} } @{$state->{players}}) {
    $text .= "$comma$player->{name}: $player->{score}";
    $comma = '; ';
  }

  $text = "none" if not length $text;

  $self->{pbot}->{conn}->privmsg($self->{channel}, "Scores: $text");
  return 'next';
}

# state subroutines

sub nogame {
  my ($self, $state) = @_;
  $state->{result} = 'nogame';
  return $state;
}

sub getplayers {
  my ($self, $state) = @_;

  my $players = $state->{players};

  my @names;
  my $unready = @$players ? @$players : 1;

  foreach my $player (@$players) {
    if (not $player->{ready}) {
      push @names, "$player->{name} (not ready)";
    } else {
      $unready--;
      push @names, $player->{name};
    }
  }

  if (not $unready) {
    $state->{result} = 'allready';
  } else {
    $players = join ', ', @names;
    $players = 'none' if not @names;
    my $msg = "Waiting for more players or for all players to ready up. Current players: $players";
    $self->{pbot}->{conn}->privmsg($self->{channel}, $msg) if $state->{ticks} % 30 == 0;
    $state->{result} = 'wait';
  }

  return $state;
}

sub round1 {
  my ($self, $state) = @_;
  $state->{truth_points} = 1000;
  $state->{lie_points} = 500;
  $self->{pbot}->{conn}->privmsg($self->{channel}, "Round 1! $state->{lie_points} for each lie. $state->{truth_points} for finding the truth.");
  $state->{result} = 'next';
  return $state;
}

sub round1q1 {
  my ($self, $state) = @_;
  $state->{init} = 1;
  $state->{counter} = 0;
  $state->{result} = 'next';
  return $state;
}

sub r1q1choosecategory {
  my ($self, $state) = @_;
  $state->{result} = $self->choosecategory($state);
  return $state;
}

sub r1q1showquestion {
  my ($self, $state) = @_;
  $self->getnewquestion($state);
  $self->showquestion($state);
  $state->{counter} = 0;
  $state->{init} = 1;
  $state->{current_lie_player} = 0;
  $state->{result} = 'next';
  return $state;
}

sub r1q1getlies {
  my ($self, $state) = @_;
  $state->{result} = $self->getlies($state);

  if ($state->{result} eq 'next') {
    $state->{counter} = 0;
    $state->{init} = 1;
  }

  return $state;
}

sub r1q1findtruth {
  my ($self, $state) = @_;
  $state->{result} = $self->findtruth($state);
  return $state;
}

sub r1q1showlies {
  my ($self, $state) = @_;
  $state->{result} = $self->showlies($state);
  return $state;
}

sub r1q1showtruth {
  my ($self, $state) = @_;
  $state->{result} = $self->showtruth($state);
  return $state;
}

sub r1q1showscore {
  my ($self, $state) = @_;
  $state->{result} = $self->showscore($state);
  return $state;
}

sub round1q2 {
  my ($self, $state) = @_;
  $state->{init} = 1;
  $state->{counter} = 0;
  $state->{result} = 'next';
  return $state;
}

sub r1q2choosecategory {
  my ($self, $state) = @_;
  $state->{result} = $self->choosecategory($state);
  return $state;
}

sub r1q2showquestion {
  my ($self, $state) = @_;
  $self->getnewquestion($state);
  $self->showquestion($state);
  $state->{counter} = 0;
  $state->{init} = 1;
  $state->{current_lie_player} = 0;
  $state->{result} = 'next';
  return $state;
}

sub r1q2getlies {
  my ($self, $state) = @_;
  $state->{result} = $self->getlies($state);

  if ($state->{result} eq 'next') {
    $state->{counter} = 0;
    $state->{init} = 1;
  }

  return $state;
}

sub r1q2findtruth {
  my ($self, $state) = @_;
  $state->{result} = $self->findtruth($state);
  return $state;
}

sub r1q2showlies {
  my ($self, $state) = @_;
  $state->{result} = $self->showlies($state);
  return $state;
}

sub r1q2showtruth {
  my ($self, $state) = @_;
  $state->{result} = $self->showtruth($state);
  return $state;
}

sub r1q2showscore {
  my ($self, $state) = @_;
  $state->{result} = $self->showscore($state);
  return $state;
}

sub round1q3 {
  my ($self, $state) = @_;
  $state->{init} = 1;
  $state->{counter} = 0;
  $state->{result} = 'next';
  return $state;
}

sub r1q3choosecategory {
  my ($self, $state) = @_;
  $state->{result} = $self->choosecategory($state);
  return $state;
}

sub r1q3showquestion {
  my ($self, $state) = @_;
  $self->getnewquestion($state);
  $self->showquestion($state);
  $state->{counter} = 0;
  $state->{init} = 1;
  $state->{current_lie_player} = 0;
  $state->{result} = 'next';
  return $state;
}

sub r1q3getlies {
  my ($self, $state) = @_;
  $state->{result} = $self->getlies($state);

  if ($state->{result} eq 'next') {
    $state->{counter} = 0;
    $state->{init} = 1;
  }

  return $state;
}

sub r1q3findtruth {
  my ($self, $state) = @_;
  $state->{result} = $self->findtruth($state);
  return $state;
}

sub r1q3showlies {
  my ($self, $state) = @_;
  $state->{result} = $self->showlies($state);
  return $state;
}

sub r1q3showtruth {
  my ($self, $state) = @_;
  $state->{result} = $self->showtruth($state);
  return $state;
}

sub r1q3showscore {
  my ($self, $state) = @_;
  $state->{result} = $self->showscore($state);
  return $state;
}

sub round2 {
  my ($self, $state) = @_;
  $state->{truth_points} = 1500;
  $state->{lie_points} = 1000;
  $self->{pbot}->{conn}->privmsg($self->{channel}, "Round 2! $state->{lie_points} for each lie. $state->{truth_points} for finding the truth.");
  $state->{result} = 'next';
  return $state;
}

sub round2q1 {
  my ($self, $state) = @_;
  $state->{init} = 1;
  $state->{counter} = 0;
  $state->{result} = 'next';
  return $state;
}

sub r2q1choosecategory {
  my ($self, $state) = @_;
  $state->{result} = $self->choosecategory($state);
  return $state;
}

sub r2q1showquestion {
  my ($self, $state) = @_;
  $self->getnewquestion($state);
  $self->showquestion($state);
  $state->{counter} = 0;
  $state->{init} = 1;
  $state->{current_lie_player} = 0;
  $state->{result} = 'next';
  return $state;
}

sub r2q1getlies {
  my ($self, $state) = @_;
  $state->{result} = $self->getlies($state);

  if ($state->{result} eq 'next') {
    $state->{counter} = 0;
    $state->{init} = 1;
  }

  return $state;
}

sub r2q1findtruth {
  my ($self, $state) = @_;
  $state->{result} = $self->findtruth($state);
  return $state;
}

sub r2q1showlies {
  my ($self, $state) = @_;
  $state->{result} = $self->showlies($state);
  return $state;
}

sub r2q1showtruth {
  my ($self, $state) = @_;
  $state->{result} = $self->showtruth($state);
  return $state;
}

sub r2q1showscore {
  my ($self, $state) = @_;
  $state->{result} = $self->showscore($state);
  return $state;
}

sub round2q2 {
  my ($self, $state) = @_;
  $state->{init} = 1;
  $state->{counter} = 0;
  $state->{result} = 'next';
  return $state;
}

sub r2q2choosecategory {
  my ($self, $state) = @_;
  $state->{result} = $self->choosecategory($state);
  return $state;
}

sub r2q2showquestion {
  my ($self, $state) = @_;
  $self->getnewquestion($state);
  $self->showquestion($state);
  $state->{counter} = 0;
  $state->{init} = 1;
  $state->{current_lie_player} = 0;
  $state->{result} = 'next';
  return $state;
}

sub r2q2getlies {
  my ($self, $state) = @_;
  $state->{result} = $self->getlies($state);

  if ($state->{result} eq 'next') {
    $state->{counter} = 0;
    $state->{init} = 1;
  }

  return $state;
}

sub r2q2findtruth {
  my ($self, $state) = @_;
  $state->{result} = $self->findtruth($state);
  return $state;
}

sub r2q2showlies {
  my ($self, $state) = @_;
  $state->{result} = $self->showlies($state);
  return $state;
}

sub r2q2showtruth {
  my ($self, $state) = @_;
  $state->{result} = $self->showtruth($state);
  return $state;
}

sub r2q2showscore {
  my ($self, $state) = @_;
  $state->{result} = $self->showscore($state);
  return $state;
}

sub round2q3 {
  my ($self, $state) = @_;
  $state->{init} = 1;
  $state->{counter} = 0;
  $state->{result} = 'next';
  return $state;
}

sub r2q3choosecategory {
  my ($self, $state) = @_;
  $state->{result} = $self->choosecategory($state);
  return $state;
}

sub r2q3showquestion {
  my ($self, $state) = @_;
  $self->getnewquestion($state);
  $self->showquestion($state);
  $state->{counter} = 0;
  $state->{init} = 1;
  $state->{current_lie_player} = 0;
  $state->{result} = 'next';
  return $state;
}

sub r2q3getlies {
  my ($self, $state) = @_;
  $state->{result} = $self->getlies($state);

  if ($state->{result} eq 'next') {
    $state->{counter} = 0;
    $state->{init} = 1;
  }

  return $state;
}

sub r2q3findtruth {
  my ($self, $state) = @_;
  $state->{result} = $self->findtruth($state);
  return $state;
}

sub r2q3showlies {
  my ($self, $state) = @_;
  $state->{result} = $self->showlies($state);
  return $state;
}

sub r2q3showtruth {
  my ($self, $state) = @_;
  $state->{result} = $self->showtruth($state);
  return $state;
}

sub r2q3showscore {
  my ($self, $state) = @_;
  $state->{result} = $self->showscore($state);
  return $state;
}

sub round3 {
  my ($self, $state) = @_;
  $state->{truth_points} = 2000;
  $state->{lie_points} = 1500;
  $self->{pbot}->{conn}->privmsg($self->{channel}, "Round 3! $state->{lie_points} for each lie. $state->{truth_points} for finding the truth.");
  $state->{result} = 'next';
  return $state;
}

sub round3q1 {
  my ($self, $state) = @_;
  $state->{init} = 1;
  $state->{counter} = 0;
  $state->{result} = 'next';
  return $state;
}

sub r3q1choosecategory {
  my ($self, $state) = @_;
  $state->{result} = $self->choosecategory($state);
  return $state;
}

sub r3q1showquestion {
  my ($self, $state) = @_;
  $self->getnewquestion($state);
  $self->showquestion($state);
  $state->{counter} = 0;
  $state->{init} = 1;
  $state->{current_lie_player} = 0;
  $state->{result} = 'next';
  return $state;
}

sub r3q1getlies {
  my ($self, $state) = @_;
  $state->{result} = $self->getlies($state);

  if ($state->{result} eq 'next') {
    $state->{counter} = 0;
    $state->{init} = 1;
  }

  return $state;
}

sub r3q1findtruth {
  my ($self, $state) = @_;
  $state->{result} = $self->findtruth($state);
  return $state;
}

sub r3q1showlies {
  my ($self, $state) = @_;
  $state->{result} = $self->showlies($state);
  return $state;
}

sub r3q1showtruth {
  my ($self, $state) = @_;
  $state->{result} = $self->showtruth($state);
  return $state;
}

sub r3q1showscore {
  my ($self, $state) = @_;
  $state->{result} = $self->showscore($state);
  return $state;
}

sub round3q2 {
  my ($self, $state) = @_;
  $state->{init} = 1;
  $state->{counter} = 0;
  $state->{result} = 'next';
  return $state;
}

sub r3q2choosecategory {
  my ($self, $state) = @_;
  $state->{result} = $self->choosecategory($state);
  return $state;
}

sub r3q2showquestion {
  my ($self, $state) = @_;
  $self->getnewquestion($state);
  $self->showquestion($state);
  $state->{counter} = 0;
  $state->{init} = 1;
  $state->{current_lie_player} = 0;
  $state->{result} = 'next';
  return $state;
}

sub r3q2getlies {
  my ($self, $state) = @_;
  $state->{result} = $self->getlies($state);

  if ($state->{result} eq 'next') {
    $state->{counter} = 0;
    $state->{init} = 1;
  }

  return $state;
}

sub r3q2findtruth {
  my ($self, $state) = @_;
  $state->{result} = $self->findtruth($state);
  return $state;
}

sub r3q2showlies {
  my ($self, $state) = @_;
  $state->{result} = $self->showlies($state);
  return $state;
}

sub r3q2showtruth {
  my ($self, $state) = @_;
  $state->{result} = $self->showtruth($state);
  return $state;
}

sub r3q2showscore {
  my ($self, $state) = @_;
  $state->{result} = $self->showscore($state);
  return $state;
}

sub round3q3 {
  my ($self, $state) = @_;
  $state->{init} = 1;
  $state->{counter} = 0;
  $state->{result} = 'next';
  return $state;
}

sub r3q3choosecategory {
  my ($self, $state) = @_;
  $state->{result} = $self->choosecategory($state);
  return $state;
}

sub r3q3showquestion {
  my ($self, $state) = @_;
  $self->getnewquestion($state);
  $self->showquestion($state);
  $state->{counter} = 0;
  $state->{init} = 1;
  $state->{current_lie_player} = 0;
  $state->{result} = 'next';
  return $state;
}

sub r3q3getlies {
  my ($self, $state) = @_;
  $state->{result} = $self->getlies($state);

  if ($state->{result} eq 'next') {
    $state->{counter} = 0;
    $state->{init} = 1;
  }

  return $state;
}

sub r3q3findtruth {
  my ($self, $state) = @_;
  $state->{result} = $self->findtruth($state);
  return $state;
}

sub r3q3showlies {
  my ($self, $state) = @_;
  $state->{result} = $self->showlies($state);
  return $state;
}

sub r3q3showtruth {
  my ($self, $state) = @_;
  $state->{result} = $self->showtruth($state);
  return $state;
}

sub r3q3showscore {
  my ($self, $state) = @_;
  $state->{result} = $self->showscore($state);
  return $state;
}

sub round4 {
  my ($self, $state) = @_;
  $state->{truth_points} = 3000;
  $state->{lie_points} = 2000;
  $self->{pbot}->{conn}->privmsg($self->{channel}, "FINAL ROUND! FINAL QUESTION! $state->{lie_points} for each lie. $state->{truth_points} for finding the truth.");
  $state->{result} = 'next';
  return $state;
}

sub round4q1 {
  my ($self, $state) = @_;
  $state->{init} = 1;
  $state->{counter} = 0;
  $state->{result} = 'next';
  return $state;
}

sub r4q1choosecategory {
  my ($self, $state) = @_;
  $state->{result} = $self->choosecategory($state);
  return $state;
}

sub r4q1showquestion {
  my ($self, $state) = @_;
  $self->getnewquestion($state);
  $self->showquestion($state);
  $state->{counter} = 0;
  $state->{init} = 1;
  $state->{current_lie_player} = 0;
  $state->{result} = 'next';
  return $state;
}

sub r4q1getlies {
  my ($self, $state) = @_;
  $state->{result} = $self->getlies($state);

  if ($state->{result} eq 'next') {
    $state->{counter} = 0;
    $state->{init} = 1;
  }

  return $state;
}

sub r4q1findtruth {
  my ($self, $state) = @_;
  $state->{result} = $self->findtruth($state);
  return $state;
}

sub r4q1showlies {
  my ($self, $state) = @_;
  $state->{result} = $self->showlies($state);
  return $state;
}

sub r4q1showtruth {
  my ($self, $state) = @_;
  $state->{result} = $self->showtruth($state);
  return $state;
}

sub r4q1showscore {
  my ($self, $state) = @_;
  $state->{result} = $self->showscore($state);
  return $state;
}

sub gameover {
  my ($self, $state) = @_;

  $self->{pbot}->{conn}->privmsg($self->{channel}, "Game over!");

  my $players = $state->{players};
  foreach my $player (@$players) {
    $player->{ready} = 0;
    $player->{missedinputs} = 0;
    $player->{score} = 0;
  }

  $state->{result} = 'next';
  return $state;
}

1;