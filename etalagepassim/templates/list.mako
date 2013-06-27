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


<%def name="metas()" filter="trim">
    <%parent:metas/>
    <meta name="robots" content="noindex">
</%def>


<%def name="results()" filter="trim">
    % if errors is None:
        % if len(ids_by_territory_and_coverage) == 0 and len(multimodal_info_services) == 0:
        <div>
            <em>${_('No organism found.')}</em>
        </div>
        % else:
            % if len(multimodal_info_services):
        <h3>${_('Multimodal Information Services')}</h3>
        <%self:results_table_multimodal info_services="${multimodal_info_services}"/>
            % endif
            % if len(ids_by_territory_and_coverage):
        <%self:results_table/>
            % endif
        % endif
    % endif
    % if ctx.container_base_url is None and (inputs.get('term') is None or inputs.get('term') != 'FRANCE'):
        <p>
            <a class="btn btn-primary" href="${urls.get_url(ctx, 'liste', coverage = 'Nationale')}" rel="tooltip" \
title="${_('Search services for whole France')}">
                <i class="icon-globe icon-white"></i> ${_('Search service for whole France')}
            </a>
        </p>
    % endif
</%def>


<%def name="results_table()" filter="trim">
    % for coverage, territories_ids in sorted(territories_id_by_coverage.iteritems(), key = lambda t: model.Poi.weight_by_coverage[t[0]]):
<%
        territories = sorted(
            [
                ramdb.territory_by_id[territory_id]
                for territory_id in territories_ids
                ],
            key = lambda territory: getattr(territory, 'population', 0),
            )
%>
        % for territory in territories:
        <h3>${_("{0} Information Services for {1}").format(coverage, territory.main_postal_distribution_str)}</h3>
        <table class="table table-bordered table-condensed table-responsive table-result table-striped">
            <thead>
                <tr>
                    <th></th>
                    <th>${_('Name')}</th>
                    <th>${_('Transport type')}</th>
                </tr>
            </thead>
            <tbody>
            % for info_service_id in ids_by_territory_and_coverage.get((territory_id, coverage)):
<%
                info_service = model.Poi.instance_by_id.get(info_service_id)
%>
                <tr>
                    <td>
                        <a class="btn btn-primary internal" rel="tooltip" title="${_('Transport offer website.')}" \
href="${urls.get_url(ctx, 'organismes', info_service.slug, info_service._id)}">
                            <i class="icon-globe icon-white"></i>
                        </a>
                    </td>
                    <td>
                        <a class="internal" href="${urls.get_url(ctx, 'organismes', info_service.slug, info_service._id)}">${info_service.name}</a>
                    </td>
                    <td>${markupsafe.escape(u' ').join(sorted(transport_types_by_id.get(info_service._id)))}</td>
                </tr>
            % endfor
            </tbody>
        </table>
        % endfor
    % endfor
</%def>


<%def name="results_table_multimodal(info_services)" filter="trim">
        <table class="table table-bordered table-condensed table-responsive table-result table-striped">
            <thead>
                <tr>
                    <th></th>
                    <th>${_('Name')}</th>
                    <th>${_('Transport type')}</th>
                </tr>
            </thead>
            <tbody>
        % for info_service in info_services:
                <tr>
                    <td>
                        <a class="btn btn-primary internal" rel="tooltip" title="${_('Transport offer website.')}" \
href="${urls.get_url(ctx, 'organismes', info_service.slug, info_service._id)}">
                            <i class="icon-globe icon-white"></i>
                        </a>
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
                    transport_types.add(markupsafe.Markup(
                        u'<a href="#" rel="tooltip" title="{0}"><img alt="{0}" src="/img/types-de-transports/{1}.png"></a>'
                        ).format(field.value, strings.slugify(field.value)))
            elif use_transport_offers_covered_territories and field.id == 'territories' \
                    and field_slug == 'territoire-couvert' and field.value is not None:
                for territory_id in field.value:
                    territory = ramdb.territory_by_id.get(territory_id)
                    if territory is not None:
                        covered_territories_postal_distribution_str.add(territory.main_postal_distribution_str)
%>\
                    <td>${markupsafe.escape(u' ').join(sorted(transport_types))}</td>
                </tr>
        % endfor
            </tbody>
        </table>
</%def>


<%def name="title_content()" filter="trim">
${_(u'List')} - ${parent.title_content()}
</%def>

