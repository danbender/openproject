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

class Journal::ChangesetJournal < Journal::BaseJournal
  self.table_name = "changeset_journals"

  acts_as_activity_provider type: 'changesets',
                            permission: :view_changesets

  def self.extend_event_query(journals_table, activity_journals_table, query)
    repositories_table = Arel::Table.new(:repositories)

    query = query.join(repositories_table).on(activity_journals_table[:repository_id].eq(repositories_table[:id]))
    [repositories_table, query]
  end

  def self.event_query_projection(journals_table, activity_journals_table)
    repositories_table = Arel::Table.new(:repositories)

    [
      activity_journals_table[:revision].as('revision'),
      activity_journals_table[:comments].as('comments'),
      activity_journals_table[:committed_on].as('committed_on'),
      repositories_table[:project_id].as('project_id'),
      repositories_table[:type].as('repository_type')
    ]
  end

  def self.format_event(event, event_data)
    committed_on = event_data['committed_on']
    committed_date = committed_on.is_a?(String) ? DateTime.parse(committed_on)
                                                : committed_on

    event.event_title = self.event_title event_data
    event.event_description = self.split_comment(event_data['comments']).last
    event.event_datetime = committed_date
    event.event_path = self.event_path event_data
    event.event_url = self.event_url event_data

    event
  end

  private

  def self.event_title(event)
    revision = self.format_revision(event)

    short_comment = self.split_comment(event['comments']).first

    title = "#{l(:label_revision)} #{revision}"
    title << (short_comment.blank? ? '' : (': ' + short_comment))
  end

  def self.format_revision(event)
    repository_class = event['repository_type'].constantize

    repository_class.respond_to?(:format_revision) ? repository_class.format_revision(event['revision'])
                                                   : event['revision']
  end

  def self.split_comment(comments)
    comments =~ /\A(.+?)\r?\n(.*)\z/m
    short_comments = $1 || comments
    long_comments = $2.to_s.strip

    [short_comments, long_comments]
  end

  def self.event_path(event)
    Rails.application.routes.url_helpers.revisions_project_repository_path(self.url_helper_parameter(event))
  end

  def self.event_url(event)
    Rails.application.routes.url_helpers.revisions_project_repository_url(self.url_helper_parameter(event),
                                                                          host: ::Setting.host_name)
  end

  def self.url_helper_parameter(event)
    { project_id: event['project_id'], rev: event['revision'] }
  end
end
