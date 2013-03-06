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
import urlparse

from etalage import conf, model, ramdb
%>


<%inherit file="/generic/index.mako"/>


<%def name="footer_actions()" filter="trim">
    % if conf['data_email'] is not None:
            <p class="pull-right">
                <a class="label label-info" href="mailto:${u','.join(conf['data_email'])}?subject=${u'Nouvelle fiche Passim+'.replace(u' ', u'%20')}&body=${u'''
Veuillez ajouter dans l'annuaire Passim+ le service d'information suivant :

Nom : ...
Couverture géographique : ....
Modes de transport : ....
Site web : ...
Application mobile : ...
Centre d'appel : ...
Guichet d'information : ...
OpenData : ...
Notes : ...
'''.strip().replace(u' ', u'%20').replace(u'\n', u'%0a')}">Ajouter une fiche</a>
            </p>
    % endif
</%def>


<%def name="scripts()" filter="trim">
    <%parent:scripts/>
    <script src="/js/bind.js"></script>
    <script src="/js/categories.js"></script>
    <script src="/js/form.js"></script>
    <script src="/js/territories.js"></script>
    <script>
var etalage = etalage || {};
etalage.miscUrl = ${conf['images.misc.url'] | n, js};
etalage.territories.autocompleterUrl = ${urlparse.urljoin(conf['territoria_url'],
    '/api/v1/autocomplete-territory') | n, js};
etalage.territories.kinds = ${ctx.autocompleter_territories_kinds | n, js};
    % if ctx.base_territory is not None:
etalage.territories.base_territory = ${ctx.base_territory.main_postal_distribution_str | n, js};
    % endif
etalage.params = ${inputs | n, js};
    </script>
</%def>


<%def name="search_form_field_coverages()" filter="trim">
    % if model.Poi.is_search_param_visible(ctx, 'coverage'):
<%
        error = errors.get('coverages') if errors is not None else None
        if error and isinstance(error, dict):
            error_index, error_message = sorted(error.iteritems())[0]
        else:
            error_index = None
            error_message = error
%>\
                <div class="control-group${' error' if error else ''}">
                    <label class="control-label" for="coverage">Couverture territoriale :</label>
                    <div class="controls">
        % if coverages:
            % for coverage_index, coverage in enumerate(coverages):
                % if (error is None or coverage_index not in error):
                        <label class="checkbox"><input checked name="coverage" type="checkbox" value="${coverage}">
                            <span class="label label-success"><i class="icon-tag icon-white"></i>
                            ${coverage}</span></label>
                % endif
            % endfor
        % endif
                        <select id="coverage" name="coverage">
                            <option value=""></option>
<%
        coverages1 = [
            coverage1
            for weight, coverage1 in sorted(
                (
                    model.Poi.weight_by_coverage.get(coverage1, 100),
                    coverage1,
                    )
                for coverage1 in model.Poi.ids_by_coverage.iterkeys()
                if coverage1 not in (coverages or [])
                )
            ]
%>\
            % for coverage in coverages1:
                            <option>${coverage}</option>
            % endfor
                        </select>
            % if error_message:
                        <span class="help-inline">${error_message}</span>
            % endif
                    </div>
                </div>
    % endif
</%def>


<%def name="search_form_field_schemas_name()" filter="trim">
    % if model.Poi.is_search_param_visible(ctx, 'schema'):
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
                if schema_name not in (
                    u'CalculDItineraires',
                    u'OffreTransport',
                    u'OperateurServiceInformation',
                    u'PageWeb',
                    )
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
    % endif
</%def>


<%def name="search_form_field_transport_modes()" filter="trim">
    % if model.Poi.is_search_param_visible(ctx, 'transport_mode'):
<%
        error = errors.get('transport_modes') if errors is not None else None
        if error and isinstance(error, dict):
            error_index, error_message = sorted(error.iteritems())[0]
        else:
            error_index = None
            error_message = error
%>\
                <div class="control-group${' error' if error else ''}">
                    <label class="control-label" for="transport_mode">Mode(s) de transport(s) :</label>
                    <div class="controls">
        % if transport_modes:
            % for transport_mode_index, transport_mode in enumerate(transport_modes):
                % if (error is None or transport_mode_index not in error):
                        <label class="checkbox"><input checked name="transport_mode" type="checkbox" value="${transport_mode}">
                            <span class="label label-success"><i class="icon-tag icon-white"></i>
                            ${transport_mode}</span></label>
                % endif
            % endfor
        % endif
                        <select id="transport_mode" name="transport_mode">
                            <option value=""></option>
<%
        transport_modes1 = [
            transport_mode1
            for slug, transport_mode1 in sorted(
                (strings.slugify(transport_mode1), transport_mode1)
                for transport_mode1 in model.Poi.ids_by_transport_mode.iterkeys()
                )
            if transport_mode1 not in (transport_modes or [])
            ]
%>\
            % for transport_mode in transport_modes1:
                            <option>${transport_mode}</option>
            % endfor
                        </select>
            % if error_message:
                        <span class="help-inline">${error_message}</span>
            % endif
                    </div>
                </div>
    % endif
</%def>


<%def name="search_form_field_transport_types()" filter="trim">
    % if model.Poi.is_search_param_visible(ctx, 'transport_type'):
<%
        error = errors.get('transport_types') if errors is not None else None
        if error and isinstance(error, dict):
            error_index, error_message = sorted(error.iteritems())[0]
        else:
            error_index = None
            error_message = error
%>\
                <div class="control-group${' error' if error else ''}">
                    <label class="control-label" for="transport_type">Type(s) de transport(s) :</label>
                    <div class="controls">
        % if transport_types:
            % for transport_type_index, transport_type in enumerate(transport_types):
                % if (error is None or transport_type_index not in error):
                        <label class="checkbox"><input checked name="transport_type" type="checkbox" value="${transport_type}">
                            <span class="label label-success"><i class="icon-tag icon-white"></i>
                            ${transport_type}</span></label>
                % endif
            % endfor
        % endif
                        <select id="transport_type" name="transport_type">
                            <option value=""></option>
<%
        transport_types1 = [
            transport_type1
            for slug, transport_type1 in sorted(
                (strings.slugify(transport_type1), transport_type1)
                for transport_type1 in model.Poi.ids_by_transport_type.iterkeys()
                )
            if transport_type1 not in (transport_types or [])
            ]
%>\
            % for transport_type in transport_types1:
                            <option>${transport_type}</option>
            % endfor
                        </select>
            % if error_message:
                        <span class="help-inline">${error_message}</span>
            % endif
                    </div>
                </div>
    % endif
</%def>


<%def name="search_form_fields()" filter="trim">
                <%self:search_form_field_schemas_name/>
                <%self:search_form_field_coverages/>
                <%self:search_form_field_transport_types/>
                <%self:search_form_field_transport_modes/>
                <%self:search_form_field_term/>
                <%self:search_form_field_territory/>
                <%self:search_form_field_filter/>
</%def>
