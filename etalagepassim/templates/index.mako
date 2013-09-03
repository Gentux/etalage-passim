## -*- coding: utf-8 -*-


## Etalage-Passim -- Customization of Etalage for Passim
## By: Emmanuel Raviart <eraviart@easter-eggs.com>
##
## Copyright (C) 2011, 2012, 2013 Easter-eggs
## http://gitorious.org/passim/etalage-passim
##
## This file is part of Etalage-Passim.
##
## Etalage-Passim is free software; you can redistribute it and/or modify
## it under the terms of the GNU Affero General Public License as
## published by the Free Software Foundation, either version 3 of the
## License, or (at your option) any later version.
##
## Etalage-Passim is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Affero General Public License for more details.
##
## You should have received a copy of the GNU Affero General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.


<%!
import urlparse
from biryani import strings

from etalagepassim import conf, model, ramdb, urls


def is_category_autocompleter_empty(categories):
    is_empty = False
    possible_pois_id = ramdb.intersection_set(
        model.Poi.ids_by_category_slug.get(category_slug)
        for category_slug in categories
        if model.Poi.ids_by_category_slug.get(category_slug)
        )
    if possible_pois_id is not None:
        categories_infos = sorted(
            (-count, category_slug)
            for count, category_slug in (
                (
                    len(set(model.Poi.ids_by_category_slug.get(category_slug, [])).intersection(possible_pois_id)),
                    category_slug,
                    )
                for category_slug in ramdb.iter_categories_slug(tags_slug = categories)
                if category_slug not in categories
                )
            if count > 0 and count != len(possible_pois_id)
            )
        if not categories_infos:
            is_empty = True
    return is_empty
%>


<%inherit file="/site.mako"/>


<%def name="container_content()" filter="trim">
        % if ctx.container_base_url is None or ctx.gadget_id is None:
        <div class="container">
            <%self:search_form/>
        </div>
        % endif
        <%self:results/>
</%def>


<%def name="export_link()" filter="trim">
<%
    url_args = {}
    for name, value in sorted(inputs.iteritems()):
        name = model.Poi.rename_input_to_param(name)
        if name in ('accept', 'submit'):
            continue
        if value is None or value == u'':
            continue
        url_args[name] = value
    url_args['accept'] = 1
%>\
                <a href="${urls.get_url(ctx, 'export', 'annuaire', 'csv', **url_args)}">
                    ${_('Export')}
                </a>
</%def>


<%def name="scripts()" filter="trim">
    <%parent:scripts/>
    <script src="/js/bind.js"></script>
    <script src="/js/search.js"></script>
    <script>
var etalagepassim = etalagepassim || {};
etalagepassim.miscUrl = ${conf['images.misc.url'] | n, js};
etalagepassim.search.autocompleterUrl = ${urlparse.urljoin(conf['territoria_url'], '/api/v1/autocomplete-territory') | n, js};
etalagepassim.search.kinds = ${ctx.autocompleter_territories_kinds | n, js};
    % if ctx.base_territory is not None:
etalagepassim.search.base_territory = ${ctx.base_territory.main_postal_distribution_str | n, js};
    % endif
etalagepassim.params = ${inputs | n, js};
    </script>
</%def>


<%def name="scripts_domready_content()" filter="trim">
    etalagepassim.bind.loadingGif();
    etalagepassim.search.createAutocompleter({
        inputSelector: '#term',
        wording: {
            categories: ${_('Categories') | n, js},
            names: ${_('Names') | n, js},
            territories: ${_('Territories') | n, js}
        }
    });
    etalagepassim.search.initGeolocation({
        buttonSelector: '#btn-geolocation',
        wording: {
            'permission denied': ${_('Permission denied by user') | n, js},
            'position unavailable': ${_('Geolocation unavaible') | n, js},
            'timeout': ${_('Geolocation timed out') | n, js}
        }
    });
    <%parent:scripts_domready_content/>
    $("[rel=tooltip]").tooltip()
</%def>


<%def name="search_form()" filter="trim">
            <form action="${urls.get_url(ctx, 'liste')}" class="form-inline internal" id="search-form" method="get">
                <%self:search_form_hidden/>
                <%self:search_form_field/>
            </form>
</%def>


<%def name="search_form_field()" filter="trim">
<%
    error = errors.get('term') if errors is not None else None
%>\
                <div class="control-group">
                    <label class="control-label" for="term">${_("Find a service")} :</label>
                    <div class="controls input-prepend">
                        <a class="btn btn-primary" href="#" id="btn-geolocation" rel="tooltip" \
title="${_('Use your GPS')}">
                            <i class="icon-globe icon-white"></i>
                        </a>
                        <input autocomplete="off" class="input-xlarge" id="term" name="term" type="text" \
value="${data['geolocation'].main_postal_distribution_str if data.get('geolocation') else (inputs['term'] or '')}">
                    </div>
    % if error:
                    <span class="help-inline">${error}</span>
    % endif
                </div>
</%def>


<%def name="search_form_hidden()" filter="trim">
<%
    search_params_name = model.Poi.get_search_params_name(ctx)
%>\
    % for name, value in sorted(inputs.iteritems()):
<%
        name = model.Poi.rename_input_to_param(name)
        if name in search_params_name and model.Poi.is_search_param_visible(ctx, name):
            continue
        if name in model.Poi.get_visibility_params_names(ctx):
            continue
        if name in ('bbox', 'coverage', 'page'):
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


<%def name="share_link()" filter="trim">
<%
    url_args = {}
    for name, value in sorted(inputs.iteritems()):
        name = model.Poi.rename_input_to_param(name)
        if name in ('accept', 'submit'):
            continue
        if value is None or value == u'':
            continue
        url_args[name] = value
%>\
                            <a href="${urls.get_url(ctx, 'gadget', **url_args)}">${_('Share')}</a>
</%def>
