## -*- coding: utf-8 -*-


## Etalage -- Open Data POIs portal
## By: Emmanuel Raviart <eraviart@easter-eggs.com>
##
## Copyright (C) 2011, 2012 Easter-eggs
## http://gitorious.org/infos-pratiques/etalage
##
## This file is part of Etalage.
##
## Etalage is free software; you can redistribute it and/or modify
## it under the terms of the GNU Affero General Public License as
## published by the Free Software Foundation, either version 3 of the
## License, or (at your option) any later version.
##
## Etalage is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Affero General Public License for more details.
##
## You should have received a copy of the GNU Affero General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.


<%!
    from etalage import model, ramdb
%>


<%inherit file="/generic/poi.mako"/>


<%def name="field_last_update(poi, depth = 0)" filter="trim">
</%def>


<%def name="field_value_link(field, depth = 0)" filter="trim">
<%
    target = ramdb.pois_by_id.get(field.value)
%>\
    % if target is None:
            <em class="field-value">Lien manquant</em>
    % else:
            <div class="field-value offset1"><%self:fields depth="${depth + 1}" poi="${target}"/></div>
    % endif
</%def>


<%def name="field_value_links(field, depth = 0)" filter="trim">
    % if len(field.value) == 1:
<%
        single_field = model.Field(id = 'link', value = field.value[0])
%>\
<%self:field_value depth="${depth}" field="${single_field}"/>
    % else:
            <ul class="field-value">
        % for target_id in field.value:
<%
            target = ramdb.pois_by_id.get(target_id)
            if target is None:
                continue
%>\
                <li>
                    <div class="field-value"><%self:fields depth="${depth + 1}" poi="${target}"/></div>
                </li>
        % endfor
            </ul>
    % endif
</%def>

