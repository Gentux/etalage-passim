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
import markupsafe

from etalage import model, ramdb, urls

from biryani import strings
%>


<%inherit file="/generic/list.mako"/>


<%def name="results_table()" filter="trim">
        <table class="table table-bordered table-condensed table-striped">
            <thead>
                <tr>
                    <th>Nom</th>
                    <th>Couverture territoriale</th>
                    <th>Territoire couvert</th>
                </tr>
            </thead>
            <tbody>
        % for info_service in pager.items:
                <tr>
                    <td>
                        <a class="internal" href="${urls.get_url(ctx, 'organismes', info_service.slug, info_service._id)}">${info_service.name}</a>
                    </td>
<%
    for field in info_service.fields:
        if field.id == 'links' and strings.slugify(field.label) == 'offres-de-transport':
            transport_offers = [
                transport_offer
                for transport_offer in (
                    model.Poi.instance_by_id.get(transport_offer_id)
                    for transport_offer_id in field.value
                    )
                if transport_offer is not None
                ] or None if field.value is not None else None
            break
    else:
        transport_offers = None
    coverages = set()
    covered_territories_postal_distribution_str = set()
    for transport_offer in (transport_offers or []):
        for field in transport_offer.fields:
            field_slug = strings.slugify(field.label)
            if field.id == 'select' and field_slug == 'couverture-territoriale' and field.value is not None:
                coverages.add(field.value)
            elif field.id == 'territories' and field_slug == 'territoire-couvert' and field.value is not None:
                for territory_id in field.value:
                    territory = ramdb.territory_by_id.get(territory_id)
                    if territory is not None:
                        covered_territories_postal_distribution_str.add(territory.main_postal_distribution_str)
%>\
                    <td>${u', '.join(sorted(coverages))}</td>
                    <td>${u', '.join(sorted(covered_territories_postal_distribution_str))}</td>
                </tr>
        % endfor
            </tbody>
        </table>
</%def>

