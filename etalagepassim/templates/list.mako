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
import markupsafe
from biryani import strings

from etalagepassim import conf, conv, model, ramdb, urls
%>


<%inherit file="/index.mako"/>


<%def name="other_search_links()" filter="trim">
<%
    child_territories = []
    if data['term'] is not None and isinstance(data['term'], model.Territory):
        if data['term'].__class__.__name__ == 'DepartmentOfFrance':
            child_territories = [
                territory
                for territory in [
                    ramdb.territory_by_id[territory_id]
                    for territory_id in ramdb.territories_id_by_ancestor_id.get(data['term']._id, [])
                    if ramdb.territory_by_id.get(territory_id) is not None
                    ]
                if territory.__class__.__name__ == 'UrbanTransportsPerimeterOfFrance'
                ]
        if data['term'].__class__.__name__ == 'RegionOfFrance':
            child_territories = [
                territory
                for territory in [
                    ramdb.territory_by_id[territory_id]
                    for territory_id in ramdb.territories_id_by_ancestor_id.get(data['term']._id, [])
                    if ramdb.territory_by_id.get(territory_id) is not None
                    ]
                if territory.__class__.__name__ == 'DepartmentOfFrance'
                ]
%>\
        <p>
    % for child_territory in child_territories:
            <a href="${urls.get_url(ctx, 'liste', term = child_territory.main_postal_distribution_str)}">
                <h4>${_(u'Traveler info services for « {0} »').format(child_territory.main_postal_distribution_str)}\
</h4>
            </a>
    % endfor
        </p>
</%def>


<%def name="results()" filter="trim">
    % if ctx.container_base_url is None and (inputs.get('term') is None or inputs.get('term') != 'FRANCE'):
        <div class="search-navbar">
        % if data['coverage'] == 'National':
            <h3>${_("Traveler Info Services covering whole FRANCE")}</h3>
        % else:
            <h3>${_(u'Traveler Info Services List For « {0} »').format(
                data['geolocation'].main_postal_distribution_str \
                if data.get('geolocation') else (inputs['term'] or '')
                )}</h3>
        % endif
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
            <div class="btn-action pull-right">
                <a class="btn btn-primary" href="${urls.get_url(ctx, 'liste', coverage = 'National')}" \
rel="tooltip" title="${_('Search services for whole France')}">${_('France')}</a>
                <a class="btn" href="${urls.get_url(ctx, 'gadget', **url_args)}" \
rel="tooltip" title="${_('Use results as a HTML component in your website')}">${_('HTML')}</a>
            </div>
        </div>
    % endif
    % if errors is None:
        % if len(ids_by_territory_id) == 0 and len(multimodal_info_services) == 0:
        <div>
            <em>${_('No organism found.')}</em>
        </div>
        % else:
            % if len(multimodal_info_services):
        <h4>${_('Multimodal Information Services')}</h4>
        <%self:results_table_multimodal info_services="${multimodal_info_services}"/>
            % endif
            % if len(ids_by_territory_id):
        <%self:results_table/>
            % endif
        % endif
        <%self:other_search_links/>
    % endif
</%def>


<%def name="results_table()" filter="trim">
<%
        territories = sorted(
            [
                ramdb.territory_by_id[territory_id]
                for territory_id in ids_by_territory_id.iterkeys()
                ],
            key = lambda territory: getattr(territory, 'population', 0),
            )
%>
    % for territory in territories:
<%
        coverages = {
            'ArrondissementOfFrance': 'local',
            'CommuneOfFrance': 'local',
            'Country': 'national',
            'DepartmentOfFrance': 'departmental',
            'RegionOfFrance': 'regional',
            'UrbanTransportsPerimeterOfFrance': 'local',
            }
        coverage = _(coverages.get(territory.__class__.__name__))
        if data['coverage'] is None and coverage == _('national'):
            coverage = None
        if coverage is None:
            continue
        if data['coverage'] == 'National' and territory.__class__.__name__ != 'Country':
            continue
        if ids_by_niveau.get(coverages.get(territory.__class__.__name__)) is None:
            continue
%>
        % if data['coverage'] != 'National':
        <h4>${_("{0} Interest Traveler Info Services for {1}").format(coverage, territory.main_postal_distribution_str)}
</h4>
        % endif
        <table class="table table-bordered table-condensed table-responsive table-result table-striped">
            <thead>
                <tr>
                    <th>${_('Web site')}</th>
                    <th>${_('Name')}</th>
                    <th>${_('Transport type')}</th>
                </tr>
            </thead>
            <tbody>
<%
        info_services = sorted(
            [
                (
                    min(
                        conf['transport_types_order'].index(strings.slugify(transport_type))
                        if strings.slugify(transport_type) in conf['transport_types_order']
                        else len(conf['transport_types_order'])
                        for transport_type in transport_types_by_id.get(info_service_id, [''])
                        ),
                    model.Poi.instance_by_id.get(info_service_id)
                    )
                for info_service_id in (ids_by_niveau.get(coverages.get(territory.__class__.__name__)) or [])
                ],
            key = lambda info_services_tuple: info_services_tuple[0],
            )
%>
        % for index, info_service in info_services:
                <tr>
                    <td>
            % if web_site_by_id.get(info_service._id) is not None:
                        <a class="btn btn-primary internal" rel="tooltip" target="_blank" \
title="${_('Transport offer website.')}" href="${web_site_by_id[info_service._id]}">${_('www')}</a>
            % endif
                    </td>
                    <td>
                        <a class="internal" \
href="${urls.get_url(ctx, 'organismes', info_service.slug, info_service._id)}">${info_service.name}</a>
                    </td>
                    <td>
                        ${markupsafe.escape(u' ').join(
                            markupsafe.Markup(
                                u'<a href="#" rel="tooltip" title="{0}"><img alt="{0}" src="/img/types-de-transports/{1}.png"></a>'
                                ).format(transport_type, strings.slugify(transport_type))
                            for transport_type in sorted(
                                transport_types_by_id.get(info_service._id, []),
                                key = lambda transport_type: conf['transport_types_order'].index(
                                    strings.slugify(transport_type)
                                    ) if conf['transport_types_order'].count(strings.slugify(transport_type)) > 0
                                    else len(conf['transport_types_order']),
                                )
                            )}
                    </td>
                </tr>
        % endfor
            </tbody>
        </table>
        <%
        if territory.__class__.__name__ in ['Country', 'MetropoleOfCountry']:
            break
        %>
    % endfor
</%def>


<%def name="results_table_multimodal(info_services)" filter="trim">
        <table class="table table-bordered table-condensed table-responsive table-result table-striped">
            <thead>
                <tr>
                    <th>${_('Web site')}</th>
                    <th>${_('Name')}</th>
                    <th>${_('Transport type')}</th>
                </tr>
            </thead>
            <tbody>
        % for info_service in info_services:
                <tr>
                    <td>
                % if web_site_by_id.get(info_service._id) is not None:
                        <a class="btn btn-primary internal" rel="tooltip" target="_blank" \
title="${_('Transport offer website.')}" href="${web_site_by_id[info_service._id]}">${_('www')}</a>
                % endif
                    </td>
                    <td>
                        <a class="internal" href="${urls.get_url(ctx, 'organismes', info_service.slug, info_service._id)}">${info_service.name}</a>
                    </td>
<%
    covered_territories_postal_distribution_str = set()
    transport_offers = None
    for field in info_service.fields:
        field_slug = strings.slugify(field.label)
        if field.id == 'links' and strings.slugify(field.label) == 'offres-de-transport':
            transport_offers = [
                transport_offer
                for transport_offer in (
                    model.Poi.instance_by_id.get(transport_offer_id)
                    for transport_offer_id in field.value
                    )
                if transport_offer is not None
                ] or None if field.value is not None else None
        elif field.id == 'territories' and field_slug == 'territoire-couvert' and field.value is not None:
            for territory_id in field.value:
                territory = ramdb.territory_by_id.get(territory_id)
                if territory is not None:
                    covered_territories_postal_distribution_str.add(territory.main_postal_distribution_str)

    coverages = set()
    transport_types = set()
    use_transport_offers_covered_territories = not covered_territories_postal_distribution_str
    for transport_offer in (transport_offers or []):
        for field in transport_offer.fields:
            field_slug = strings.slugify(field.label)
            if field.id == 'select':
                if field_slug == 'couverture-territoriale' and field.value is not None:
                    coverages.add(field.value)
                elif field_slug == 'type-de-transport' and field.value is not None:
                    transport_types.add(field.value)
            elif use_transport_offers_covered_territories and field.id == 'territories' \
                    and field_slug == 'territoire-couvert' and field.value is not None:
                for territory_id in field.value:
                    territory = ramdb.territory_by_id.get(territory_id)
                    if territory is not None:
                        covered_territories_postal_distribution_str.add(territory.main_postal_distribution_str)
%>\
                    <td>
                        ${markupsafe.escape(u' ').join(
                            markupsafe.Markup(
                                u'<a href="#" rel="tooltip" title="{0}"><img alt="{0}" src="/img/types-de-transports/{1}.png"></a>'
                                ).format(transport_type, strings.slugify(transport_type))
                            for transport_type in sorted(
                                transport_types,
                                key = lambda transport_type: conf['transport_types_order'].index(
                                    strings.slugify(transport_type)
                                    ) if conf['transport_types_order'].count(strings.slugify(transport_type)) > 0
                                    else len(conf['transport_types_order']),
                                )
                            )}
                    </td>
                </tr>
        % endfor
            </tbody>
        </table>
</%def>


<%def name="title_content()" filter="trim">
<%
    search_title = ''
    if data['term'] is not None and isinstance(data['term'], model.Territory):
        search_title = data['term'].main_postal_distribution_str
    else:
        search_title = _('France')
%>\
${_(u'List')} - ${search_title} - ${parent.title_content()}
</%def>
