#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class Journal::WorkPackageJournal < Journal::BaseJournal
  self.table_name = "work_package_journals"

  acts_as_activity_provider type: 'work_packages',
                            permission: :view_work_packages

  def self.extend_event_query(journals_table, activity_journals_table, query)
    types_table = Arel::Table.new(:types)
    statuses_table = Arel::Table.new(:statuses)

    query = query.join(types_table).on(activity_journals_table[:type_id].eq(types_table[:id]))
    query = query.join(statuses_table).on(activity_journals_table[:status_id].eq(statuses_table[:id]))
    [activity_journals_table, query]
  end

  def self.event_query_projection(journals_table, activity_journals_table)
    types_table = Arel::Table.new(:types)
    statuses_table = Arel::Table.new(:statuses)

    [
      activity_journals_table[:subject].as('subject'),
      activity_journals_table[:project_id].as('project_id'),
      statuses_table[:name].as('status_name'),
      statuses_table[:is_closed].as('status_closed'),
      types_table[:name].as('type_name')
    ]
  end

  def self.format_event(event, event_data)
    event.event_title = self.event_title event_data
    event.event_type = "work_package#{self.event_type event_data}"
    event.event_path = self.event_path event_data
    event.event_url = self.event_url event_data

    event
  end

  private

  def self.event_title(event)
    title = "#{(event['is_standard']) ? l(:default_type)
                                      : "#{event['type_name']}"} ##{event['journable_id']}: #{event['subject']}"
    title << " (#{event['status_name']})" unless event['status_name'].blank?
  end

  def self.event_type(event)
    journal = Journal.find(event['event_id'])

    if journal.changed_data.empty? && !journal.initial?
       '-note'
    else
      event['status_closed'] ? '-closed' : '-edit'
    end
  end

  def self.event_path(event)
    Rails.application.routes.url_helpers.work_package_path(self.url_helper_parameter(event))
  end

  def self.event_url(event)
    Rails.application.routes.url_helpers.work_package_url(self.url_helper_parameter(event),
                                                          host: ::Setting.host_name)
  end

  def self.url_helper_parameter(event)
    version = event['version'].to_i
    anchor = event['version'].to_i - 1

    parameters = [event['journable_id']]
    parameters << { anchor: "note-#{anchor}" } if version > 1
    parameters
  end
end
