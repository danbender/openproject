#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'yaml'

require_relative 'migration_utils/queries'

class MigrateQueryTrackerReferencesToType < ActiveRecord::Migration
  include Migration::Utils

  KEY = { 'tracker_id' => 'type_id', 'tracker' => 'type' }

  def up
    say_with_time_silently "Update tracker references in queries" do
      update_query_references_with_keys(KEY)
    end
  end

  def down
    say_with_time_silently "Restore tracker references in queries" do
      update_query_references_with_keys(KEY.invert)
    end
  end
end
