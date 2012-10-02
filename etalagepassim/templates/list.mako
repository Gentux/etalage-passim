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

from etalage import conf, model, ramdb, urls

from biryani import strings
%>


<%inherit file="/generic/list.mako"/>


<%def name="results_table()" filter="trim">
        <table class="table table-bordered table-condensed table-striped">
            <thead>
                <tr>
                    <th>Nom</th>
                    <th>Type de transport</th>
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
                        u'<a href="#" rel="tooltip" title="{0}"><img alt="{0}" src="/passim-images/types-de-transports/{1}.png"></a>'
                        ).format(field.value, strings.slugify(field.value)))
            elif use_transport_offers_covered_territories and field.id == 'territories' \
                    and field_slug == 'territoire-couvert' and field.value is not None:
                for territory_id in field.value:
                    territory = ramdb.territory_by_id.get(territory_id)
                    if territory is not None:
                        covered_territories_postal_distribution_str.add(territory.main_postal_distribution_str)
%>\
                    <td>${markupsafe.escape(u' ').join(sorted(transport_types))}</td>
                    <td>${u', '.join(sorted(coverages))}</td>
                    <td>${u', '.join(sorted(covered_territories_postal_distribution_str))}</td>
                </tr>
        % endfor
            </tbody>
        </table>
</%def>


<%def name="scripts()" filter="trim">
    <%parent:scripts/>
    <script src="${conf['bootstrap.js']}"></script>
    <script>
$(function () {
    $("[rel=tooltip]")
        .tooltip()
        .on('click', function (event) {
            event.preventDefault();
        });
});
    </script>
</%def>

