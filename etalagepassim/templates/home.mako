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
        % if pager.item_count == 0:
        <div>
            <em>${_('No organism found.')}</em>
        </div>
        % else:
        <%self:last_updated_pois/>
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


<%def name="last_updated_pois()" filter="trim">
        <div class="search-navbar">
            <h3>${_("10 Last Updated Information Services")}</h3>
            <div class="btn-group pull-right">
                <a class="btn btn-warning btn-feed" href="${urls.get_url(ctx, 'feed')}" target="_blank" \
title="${_('RSS Feed')}"><i class="icon-feed"></i></a>
            </div>
        </div>
        <table class="table table-bordered table-condensed table-striped table-responsive">
            <thead>
                <tr>
                    <th>${_("Name")}</th>
                    <th>${_("Territory")}</th>
                    <th>${_("Last modification time")}</th>
                </tr>
            </thead>
            <tbody>
        % for info_service in pager.items[:pager.page_max_size]:
                <tr>
                    <td>
                        <a class="internal" \
href="${urls.get_url(ctx, 'organismes', info_service.slug, info_service._id)}">${info_service.name}</a>
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
                    <td>${u', '.join(sorted(covered_territories_postal_distribution_str))}</td>
                    <td>${info_service.last_update_datetime.strftime('%d/%m/%Y')}</td>
                </tr>
        % endfor
            </tbody>
        </table>
</%def>


<%def name="title_content()" filter="trim">
${_(u'Home')} - ${parent.title_content()}
</%def>

