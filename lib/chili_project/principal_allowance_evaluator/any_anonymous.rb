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

class ChiliProject::PrincipalAllowanceEvaluator::AnyAnonymous < ChiliProject::PrincipalAllowanceEvaluator::Base

  def self.applicable?(action, project)
    project.nil?
  end

  def self.joins(scope, action, project)
    users = User.arel_table
    roles = roles_table

    permission_matches = matches_condition(action)

    role_id = roles[:id].eq(fallback_role)
    only_anonymous_user = users[:id].eq(User.anonymous.id)

    on_condition = role_id.and(permission_matches).and(only_anonymous_user)

    anonymous_scope = users.join(roles, Arel::Nodes::OuterJoin)
                           .on(on_condition)

    scope.joins(anonymous_scope.join_sources)
  end

  def self.condition(condition, action, project)

    add_condition = roles_table[:id].not_eq(nil)


    condition.or(add_condition)
  end

  private

  def self.fallback_role
    Role.anonymous.id
  end

  def self.roles_table
    Role.arel_table.alias("roles_#{ alias_suffix }")
  end

  def self.members_table
    Member.arel_table.alias("members_#{ alias_suffix }")
  end

  def self.alias_suffix
    "any_anonymous"
  end

  def self.matches_condition(action)
    roles = roles_table

    condition = case action
                when Symbol
                  roles['permissions'].matches("%#{action}%")
                when Array
                  condition = Arel::Nodes::Equality.new(1, 0)

                  action.each do |a|
                    condition = condition.or(roles['permissions'].matches("%#{a}%"))
                  end

                  condition
                else
                  raise ArgumentError
                end

    roles.grouping(condition)
  end
end

