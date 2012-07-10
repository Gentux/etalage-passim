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
from biryani import strings

from etalage import model, ramdb
%>


<%inherit file="/generic/index.mako"/>


<%def name="search_form_field_coverage()" filter="trim">
<%
    error = errors.get('coverage') if errors is not None else None
%>\
                <div class="control-group${' error' if error else ''}">
                    <label class="control-label" for="coverage">Couverture territoriale :</label>
                    <div class="controls">
                        <select id="coverage" name="coverage">
                            <option value=""></option>
<%
    coverages = [
        coverage1
        for weight, coverage1 in sorted(
            (
                {
                    u'Départementale': 1,
                    u'Locale': 0,
                    u'Nationale': 3,
                    u'Régionale': 2,
                    }.get(coverage1, 100),
                coverage1,
                )
            for coverage1 in model.Poi.ids_by_coverage.iterkeys()
            )
        ]
%>\
        % for coverage1 in coverages:
                            <option${u' selected' if coverage1 == coverage else u''}>${coverage1}</option>
        % endfor
                        </select>
        % if error_message:
                        <span class="help-inline">${error_message}</span>
        % endif
                    </div>
                </div>
</%def>


<%def name="search_form_field_schemas()" filter="trim">
<%
    error = errors.get('schemas_name') if errors is not None else None
    if error and isinstance(error, dict):
        error_index, error_message = sorted(error.iteritems())[0]
    else:
        error_index = None
        error_message = error
%>\
                <div class="control-group${' error' if error else ''}">
                    <label class="control-label" for="schema">Support(s) de diffusion :</label>
                    <div class="controls">
    % if schemas_name:
        % for schema_name_index, schema_name in enumerate(schemas_name):
            % if (error is None or schema_name_index not in error):
                        <label class="checkbox"><input checked name="schema" type="checkbox" value="${schema_name}">
                            <span class="label label-success"><i class="icon-tag icon-white"></i>
                            ${ramdb.schema_title_by_name.get(schema_name, schema_name)}</span></label>
            % endif
        % endfor
    % endif
                        <select id="schema" name="schema">
                            <option value=""></option>
<%
    schemas_infos = [
        (schema_name, schema_title)
        for schema_slug, schema_name, schema_title in sorted(
            (strings.slugify(schema_title), schema_name, schema_title)
            for schema_name, schema_title in ramdb.schema_title_by_name.iteritems()
            if schema_name not in (schemas_name or []) and 0 < len(model.Poi.ids_by_schema_name.get(schema_name, [])) < len(model.Poi.indexed_ids)
            )
        ]
%>\
        % for schema_name, schema_title in schemas_infos:
                            <option value="${schema_name}">${schema_title}</option>
        % endfor
                        </select>
        % if error_message:
                        <span class="help-inline">${error_message}</span>
        % endif
                    </div>
                </div>
</%def>


<%def name="search_form_field_transport_type()" filter="trim">
<%
    error = errors.get('transport_type') if errors is not None else None
%>\
                <div class="control-group${' error' if error else ''}">
                    <label class="control-label" for="transport_type">Type de transport :</label>
                    <div class="controls">
                        <select id="transport_type" name="transport_type">
                            <option value=""></option>
<%
    transport_types = [
        transport_type1
        for slug, transport_type1 in sorted(
            (strings.slugify(transport_type), transport_type1)
            for transport_type1 in model.Poi.ids_by_transport_type.iterkeys()
            )
        ]
%>\
        % for transport_type1 in transport_types:
                            <option${u' selected' if transport_type1 == transport_type else u''}>${transport_type1}</option>
        % endfor
                        </select>
        % if error_message:
                        <span class="help-inline">${error_message}</span>
        % endif
                    </div>
                </div>
</%def>


<%def name="search_form_fields()" filter="trim">
                <%self:search_form_field_schemas/>
                <%self:search_form_field_coverage/>
                <%self:search_form_field_transport_type/>
                <%self:search_form_field_term/>
                <%self:search_form_field_territory/>
                <%self:search_form_field_filter/>
</%def>


<%def name="search_form_hidden()" filter="trim">
    % for name, value in sorted(inputs.iteritems()):
<%
        name = {
            'schemas_name': 'schema',
            }.get(name, name)
        if name in (
                'bbox',
                'coverage',
                'filter' if ctx.show_filter else None,
                'page',
                'schema',
                'term' if not ctx.hide_term else None,
                'territory' if not ctx.hide_territory else None,
                'transport_type',
                ):
            continue
        if value is None or value == u'':
            continue
%>\
        % if isinstance(value, list):
            % for item_value in value:
            <input name="${name}" type="hidden" value="${item_value or ''}">
            % endfor
        % else:
            <input name="${name}" type="hidden" value="${value or ''}">
        % endif
    % endfor
</%def>

