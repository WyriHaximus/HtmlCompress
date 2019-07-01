<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests\Compressor;

use WyriHaximus\HtmlCompress\Compressor\JsonCompressor;

/**
 * @internal
 */
final class JsonCompressorTest extends AbstractVendorCompressorTest
{
    const COMPRESSOR = JsonCompressor::class;

    public function providerReturn(): iterable
    {
        yield [
            '{
                "@context": "https:\/\/schema.org\/",
                "@graph": [{
                    "@context": "https:\/\/schema.org\/",
                    "@type": "BreadcrumbList",
                    "itemListElement": [{
                        "@type": "ListItem",
                        "position": 1,
                        "item": {
                            "name": "Home",
                            "@id": "http:\/\/domain.com"
                        }
                    }, {
                        "@type": "ListItem",
                        "position": 2,
                        "item": {
                            "name": "Category title",
                            "@id": "http:\/\/domain.com\/product-category\/category-name\/"
                        }
                    }, {
                        "@type": "ListItem",
                        "position": 3,
                        "item": {
                            "name": "Sub Category title",
                            "@id": "http:\/\/domain.com\/product-category\/category-name\/sub-category-name\/"
                        }
                    }]
                }, {
                    "@context": "https:\/\/schema.org\/",
                    "@graph": [{
                        "@type": "Product",
                        "@id": "http:\/\/domain.com\/product\/mijote-de-potiron\/",
                        "name": "Mijot\u00e9e de potiron",
                        "url": "http:\/\/domain.com\/product\/mijote-de-potiron\/"
                    }, {
                        "@type": "Product",
                        "@id": "http:\/\/domain.com\/product\/mijote-de-haricot-vert-2\/",
                        "name": "Mijot\u00e9e de haricot vert",
                        "url": "http:\/\/domain.com\/product\/mijote-de-haricot-vert-2\/"
                    }, {
                        "@type": "Product",
                        "@id": "http:\/\/domain.com\/product\/mijote-de-carotte-2\/",
                        "name": "Mijot\u00e9e de carotte",
                        "url": "http:\/\/domain.com\/product\/mijote-de-carotte-2\/"
                    }, {
                        "@type": "Product",
                        "@id": "http:\/\/domain.com\/product\/mijote-de-petit-pois\/",
                        "name": "Mijot\u00e9e de petit pois",
                        "url": "http:\/\/domain.com\/product\/mijote-de-petit-pois\/"
                    }, {
                        "@type": "Product",
                        "@id": "http:\/\/domain.com\/product\/mijote-de-patate-douce\/",
                        "name": "Mijot\u00e9e de patate douce",
                        "url": "http:\/\/domain.com\/product\/mijote-de-patate-douce\/"
                    }, {
                        "@type": "Product",
                        "@id": "http:\/\/domain.com\/product\/mijote-de-brocoli-2\/",
                        "name": "Mijot\u00e9e de brocoli",
                        "url": "http:\/\/domain.com\/product\/mijote-de-brocoli-2\/"
                    }]
                }]
            }',
            '{"@context":"https:\/\/schema.org\/","@graph":[{"@context":"https:\/\/schema.org\/","@type":"BreadcrumbList","itemListElement":[{"@type":"ListItem","position":1,"item":{"name":"Home","@id":"http:\/\/domain.com"}},{"@type":"ListItem","position":2,"item":{"name":"Category title","@id":"http:\/\/domain.com\/product-category\/category-name\/"}},{"@type":"ListItem","position":3,"item":{"name":"Sub Category title","@id":"http:\/\/domain.com\/product-category\/category-name\/sub-category-name\/"}}]},{"@context":"https:\/\/schema.org\/","@graph":[{"@type":"Product","@id":"http:\/\/domain.com\/product\/mijote-de-potiron\/","name":"Mijot\u00e9e de potiron","url":"http:\/\/domain.com\/product\/mijote-de-potiron\/"},{"@type":"Product","@id":"http:\/\/domain.com\/product\/mijote-de-haricot-vert-2\/","name":"Mijot\u00e9e de haricot vert","url":"http:\/\/domain.com\/product\/mijote-de-haricot-vert-2\/"},{"@type":"Product","@id":"http:\/\/domain.com\/product\/mijote-de-carotte-2\/","name":"Mijot\u00e9e de carotte","url":"http:\/\/domain.com\/product\/mijote-de-carotte-2\/"},{"@type":"Product","@id":"http:\/\/domain.com\/product\/mijote-de-petit-pois\/","name":"Mijot\u00e9e de petit pois","url":"http:\/\/domain.com\/product\/mijote-de-petit-pois\/"},{"@type":"Product","@id":"http:\/\/domain.com\/product\/mijote-de-patate-douce\/","name":"Mijot\u00e9e de patate douce","url":"http:\/\/domain.com\/product\/mijote-de-patate-douce\/"},{"@type":"Product","@id":"http:\/\/domain.com\/product\/mijote-de-brocoli-2\/","name":"Mijot\u00e9e de brocoli","url":"http:\/\/domain.com\/product\/mijote-de-brocoli-2\/"}]}]            }',
        ];
    }

    /**
     * @dataProvider providerReturn
     * @param mixed $input
     * @param mixed $expected
     */
    public function testCssMinCompress($input, $expected): void
    {
        $actual = $this->compressor->compress($input);
        self::assertSame($expected, $actual);
    }
}
