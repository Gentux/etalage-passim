/*
 * Etalage-Passim -- Customization of Etalage for Passim
 * By: Emmanuel Raviart <eraviart@easter-eggs.com>
 *
 * Copyright (C) 2011, 2012, 2013 Easter-eggs
 * http://gitorious.org/passim/etalage-passim
 *
 * This file is part of Etalage-Passim.
 *
 * Etalage-Passim is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * Etalage-Passim is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

var etalagepassim = etalagepassim || {};


etalagepassim.map = (function ($) {
    var leafletMap;

    function addFeature(feature, layer) {
        var properties = feature.properties;

        etalagepassim.map.setFeatureIcon(layer, properties);

        if ( ! properties.home) {
            var nearbyPoiCount = properties.count - properties.centerPois.length;
            var poi;
            var $popupDiv = $('<div/>');
            if (properties.count == 1 || nearbyPoiCount > 0) {
                poi = properties.centerPois[0];
                $popupDiv.append(
                    $('<a/>', {
                        'class': 'internal',
                        'data-poi-id': poi.id,
                        href: '/organismes/' + poi.slug + '/' + poi.id
                    }).append($('<strong/>').text(poi.name))
                );
                if (poi.streetAddress) {
                    $.each(poi.streetAddress.split('\n'), function (index, line) {
                        $popupDiv.append($('<div/>').text(line));
                    });
                }
                if (poi.postalDistribution) {
                    $popupDiv.append($('<div/>').text(poi.postalDistribution));
                }
            } else {
                var $ul = $('<ul/>');
                var $li;
                $.each(properties.centerPois, function (index, poi) {
                    $li = $('<li>').append(
                        $('<a/>', {
                            'class': 'internal',
                            href: '/organismes/' + poi.slug + '/' + poi.id
                        }).append($('<strong/>').text(poi.name))
                    );
                    if (poi.streetAddress) {
                        $.each(poi.streetAddress.split('\n'), function (index, line) {
                            $li.append($('<div/>').text(line));
                        });
                    }
                    if (poi.postalDistribution) {
                        $li.append($('<div/>').text(poi.postalDistribution));
                    }
                    $ul.append($li);
                });
                $popupDiv.append($ul);
            }

            if (nearbyPoiCount > 0) {
                var bbox = feature.bbox;
                var $a = $('<a/>', {
                    'class': 'bbox',
                    'data-bbox': "[" + bbox + "]",
                    href: '/carte?' + $.param($.extend({bbox: bbox.join(",")}, etalagepassim.map.geojsonParams || {}), true)
                });
                var $em = $('<em/>');
                if (properties.count == 2) {
                    $em.text('Ainsi qu\'1 autre organisme à proximité');
                } else {
                    $em.text('Ainsi que ' + (properties.count - 1) + ' autres organismes à proximité');
                }
                $popupDiv.append($('<div/>').append($a.append($em)));
            }

            layer.bindPopup($popupDiv.html());
        }
    }

    function createIcon(iconUrl) {
        return L.icon({
            iconUrl: iconUrl,
            shadowUrl: etalagepassim.map.markersUrl + '/misc/shadow.png',
            iconSize: [27, 27],
            shadowSize: [51, 27],
            iconAnchor: [14, 24]
        });
    }

    function createMap(mapDiv, bbox) {
        leafletMap = L.map(mapDiv, {
            scrollWheelZoom: false
        });

        var tileLayers = {};
        $.each(etalagepassim.map.tileLayersOptions, function (index, options) {
            tileLayers[options.name] = L.tileLayer(options.url, {
                attribution: options.attribution,
                subdomains: options.subdomains || 'abc'
            });
        });
        leafletMap.addLayer(tileLayers[etalagepassim.map.tileLayersOptions[0].name]);
        leafletMap.attributionControl.setPrefix(null); // Remove Leaflet attribution.
        if (etalagepassim.map.tileLayersOptions.length > 1) {
            L.control.layers(tileLayers, null).addTo(leafletMap);
        }

        if (window.PIE) {
            $('.leaflet-control, .leaflet-control-zoom, .leaflet-control-zoom-in, .leaflet-control-zoom-out').each(
                function () {
                    // Apply CSS3 border-radius for IE to zoom controls.
                    PIE.attach(this);
                }
            );
        }

        // Text settings
        $('.leaflet-control-zoom-in').attr('title', 'Zoomer');
        $('.leaflet-control-zoom-out').attr('title', 'Dézoomer');

        if (typeof etalagepassim.map.addFeature == "undefined" || etalagepassim.map.addFeature === null) {
            etalagepassim.map.addFeature = addFeature;
        }
        var geojsonLayer = L.geoJson(null, {
            onEachFeature: etalagepassim.map.addFeature
        }).addTo(leafletMap);
        etalagepassim.map.geojsonLayer = geojsonLayer;

        leafletMap
            .on('dragend', function (e) {
                fetchPois();
            })
            .on('layerremove', function (e) {
                if (e.layer._closeButton) {
                    delete etalagepassim.map.currentPoiId;
                }
            })
            .on('popupopen', function (e) {
                $popupDiv = $(e.popup._content);
                etalagepassim.map.currentPoiId = $popupDiv.first().data('poiId') || null;
                var bbox = $popupDiv.find('a.bbox').data('bbox');
                $('a.bbox').on('click', function (e) {
                    leafletMap.fitBounds(L.latLngBounds(
                        L.latLng(bbox[1], bbox[0]),
                        L.latLng(bbox[3], bbox[2])
                    ));
                    return false;
                });
                if (typeof etalagepassim.rpc !== "undefined" && etalagepassim.rpc !== null) {
                    $('a.internal').on('click', function (e) {
                        var path = $(this).attr('href');
                        if (path.search(/\/organismes\//) !== 0) {
                            relative_path_index = path.search(/\/organismes\//);
                            path = path.substr(relative_path_index);
                        }
                        etalagepassim.rpc.requestNavigateTo(path);
                        return false;
                    });
                }
            })
            .on('zoomend', function (e) {
                try {
                    leafletMap.getBounds();
                } catch(err) {
                    // Method getBounds fails when map center or zoom level are not yet set.
                    return;
                }
                etalagepassim.map.geojsonLayer.clearLayers();
                etalagepassim.map.layerByPoiId = {};
                fetchPois();
            });

        if (window.PIE) {
            leafletMap.on('layeradd', function (e) {
                if (e.layer._wrapper && e.layer._opened === true && e.layer._content) {
                    // Apply CSS3 border-radius for IE to popup.
                    PIE.attach(e.layer._wrapper);
                }
            });
        }
        etalagepassim.map.layerByPoiId = {};
        if (bbox) {
            leafletMap.fitBounds(L.latLngBounds(
                L.latLng(bbox[1], bbox[0]),
                L.latLng(bbox[3], bbox[2])
            ));
            fetchPois();
        } else {
            // No POI found.
            if (etalagepassim.map.center !== null) {
                leafletMap.setView(etalagepassim.map.center, leafletMap.getMaxZoom() - 3);
            } else {
                leafletMap.fitBounds(L.latLngBounds(
                    L.latLng(90, 180),
                    L.latLng(-90, -180)
                ));
            }
        }

        // Add scale to map
        L.control.scale({
            metric: true,
            imperial: false
        }).addTo(leafletMap);
    }

    function fetchPois() {
        var context = (new Date()).getTime();

        // When map is larger than 360 degrees, fix min and max longitude returned by getBounds().
        var bounds = leafletMap.getBounds();
        var northEast = bounds.getNorthEast();
        var southWest = bounds.getSouthWest();
        var lowestX = leafletMap.layerPointToContainerPoint(leafletMap.latLngToLayerPoint(L.latLng(0, -180))).x;
        var zeroX = leafletMap.layerPointToContainerPoint(leafletMap.latLngToLayerPoint(L.latLng(0, 0))).x;
        // highestX = lowestX + 2 * (zeroX - lowestX) = 2 * zeroX - lowestX
        var east = 2 * zeroX - lowestX > leafletMap.getSize().x ?  northEast.lng : 180;
        var west = lowestX < 0 ? southWest.lng : -180;
        var geojsonParams = $.extend({
                bbox: [west, southWest.lat, east, northEast.lat].join(","),
                context: context
            },
            etalagepassim.map.geojsonParams || {},
            etalagepassim.map.currentPoiId ? {current: etalagepassim.map.currentPoiId} : {},
            leafletMap.getZoom() === leafletMap.getMaxZoom() ? {enable_cluster: false} : {}
        );
        etalage.map.bbox = geojsonParams.bbox;
        $.ajax({
            url: etalagepassim.map.geojsonUrl,
            dataType: 'json',
            data: geojsonParams,
            success: function (data) {
                if (parseInt(data.properties.context, 10) !== context) {
                    return;
                }
                // setGeoJSONData(data);
                var geojsonLayer = etalagepassim.map.geojsonLayer;
                geojsonLayer.clearLayers();
                geojsonLayer.addData(data);
            },
            traditional: true
        });
    }

    function singleMarkerMap(mapDiv, latitude, longitude) {
        var latLng, map, marker, tileLayer, tileLayers;

        map = L.map(mapDiv, {
            scrollWheelZoom: false
        });

        tileLayers = {};
        $.each(etalagepassim.map.tileLayersOptions, function (index, options) {
            tileLayers[options.name] = L.tileLayer(options.url, {
                attribution: options.attribution,
                subdomains: options.subdomains || 'abc'
            });
        });
        map.addLayer(tileLayers[etalagepassim.map.tileLayersOptions[0].name]);
        map.attributionControl.setPrefix(null); // Remove Leaflet attribution.
        if (etalagepassim.map.tileLayersOptions.length > 1) {
            L.control.layers(tileLayers, null).addTo(map);
        }

        latLng = L.latLng(latitude, longitude);
        marker = L.marker(latLng);
        marker.setIcon(createIcon(etalagepassim.map.markersUrl + '/misc/blueblank.png'));
        map.addLayer(marker);

        map.setView(latLng, map.getMaxZoom() - 3);

        return map;
    }

    function setFeatureIcon(layer, properties) {
        // Icon settings
        var blueBlankIcon = createIcon(etalagepassim.map.markersUrl + '/misc/blueblank.png');
        var blueMultipleIcon = createIcon(etalagepassim.map.markersUrl + '/misc/bluemultiple.png');
        var greenValidIcon = createIcon(etalagepassim.map.markersUrl + '/misc/greenvalid.png');
        var greenMultipleIcon = createIcon(etalagepassim.map.markersUrl + '/misc/greenmultiple.png');
        var homeIcon = createIcon(etalagepassim.map.markersUrl + '/map-icons-collection-2.0/icons/home.png');
        var redInvalidIcon = createIcon(etalagepassim.map.markersUrl + '/misc/redinvalid.png');
        var redMultipleIcon = createIcon(etalagepassim.map.markersUrl + '/misc/redmultiple.png');

        etalagepassim.map.layerByPoiId[properties.id] = layer;

        if (properties.home) {
            layer.setIcon(homeIcon);
        } else {
            if (properties.count > 1) {
                if (properties.competent === true) {
                    layer.setIcon(greenMultipleIcon);
                } else if (properties.competent === false) {
                    layer.setIcon(redMultipleIcon);
                } else {
                    layer.setIcon(blueMultipleIcon);
                }
            } else {
                if (properties.competent === true) {
                    layer.setIcon(greenValidIcon);
                } else if (properties.competent === false) {
                    layer.setIcon(redInvalidIcon);
                } else {
                    layer.setIcon(blueBlankIcon);
                }
            }
        }
    }

    return {
        bbox: null,
        center: null,
        createMap: createMap,
        currentPoiId: null,
        fetchPois: fetchPois,
        geojsonLayer: null,
        geojsonParams: null,
        geojsonUrl: null,
        layerByPoiId: null,
        markersUrl: null,
        setFeatureIcon: setFeatureIcon,
        singleMarkerMap: singleMarkerMap,
        tileLayersOptions: null
    };
})(jQuery);

