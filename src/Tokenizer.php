<?php

/*
 * This file is part of HtmlCompress.
 *
 ** (c) 2014 Cees-Jan Kiewiet
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */
namespace WyriHaximus\HtmlCompress;

use \WyriHaximus\HtmlCompress\Compressor\CompressorInterface;

/**
 * Class Parser
 *
 * @package WyriHaximus\HtmlCompress
 */
class Tokenizer
{
    /**
     * @var array
     */
    protected $compressors;

    /**
     * @var Compressor\CompressorInterface
     */
    protected $defaultCompressor;
    /**
     * @var Compressor\CompressorInterface
     */
    protected $defaultCompressorClone;

    /**
     * @param string $html
     * @param array $compressors
     * @param CompressorInterface $defaultCompressor
     * @return array
     */
    public static function tokenize($html, array $compressors, CompressorInterface $defaultCompressor = null)
    {
        $self = new self($compressors, $defaultCompressor);
        return $self->parse($html);
    }

    /**
     * @param array $compressors
     * @param CompressorInterface $defaultCompressor
     */
    public function __construct(array $compressors, CompressorInterface $defaultCompressor = null)
    {
        $this->compressors = $compressors;
        $this->defaultCompressor = $defaultCompressor;
        $this->defaultCompressorClone = clone $defaultCompressor;
    }

    /**
     * @param string $html
     * @return array
     */
    public function parse($html)
    {
        $tokens = [
        new Token('', '', $html, $this->defaultCompressor),
        ];
        do {
            $compressor = array_shift($this->compressors);
            $tokens = $this->split($tokens, $compressor);
        } while (count($this->compressors) > 0);
        return $tokens;
    }

    /**
     * @param array $tokens
     * @param array $compressor
     * @return array
     */
    protected function split(array $tokens, array $compressor)
    {
        foreach ($compressor['patterns'] as $pattern) {
            foreach ($tokens as $index => $token) {
                if ($token->getCompressor() === $this->defaultCompressor) {
                    $html = preg_split($pattern, $token->getCombinedHtml());
                    preg_match_all($pattern, $token->getCombinedHtml(), $bits);

                    if (count($bits[0]) == 0) {
                        continue;
                    }

                    $newTokens = $this->walkBits($bits, $html, $compressor['compressor']);
                    if (count($newTokens) > 0) {
                        $tokens = $this->replaceToken($tokens, $index, $newTokens);
                    }
                }
            }
        }

        return $tokens;
    }

    /**
     * @param array $bits
     * @param array $html
     * @param CompressorInterface $compressor
     * @return array
     */
    protected function walkBits($bits, $html, $compressor)
    {
        $newTokens = [];
        $prepend = '';
        for ($i = 0; $i < count($bits[0]); $i++) {
            if ($bits[1][$i] === '' && $bits[2][$i] === '' && $bits[3][$i] === '') {
                continue;
            }
            $newTokens[] = new Token($prepend, $bits[1][$i], $html[$i], $this->defaultCompressorClone);
            $newTokens[] = new Token('', '', $bits[2][$i], $compressor);
            $prepend = $bits[3][$i];
        }

        if ($prepend !== '' || $html[$i] !== '') {
            $newTokens[] = new Token($prepend, '', $html[$i], $this->defaultCompressorClone);
        }

        return $newTokens;
    }

    /**
     * @param array $tokens
     * @param int $index
     * @param array $newTokens
     * @return array
     */
    protected function replaceToken($tokens, $index, $newTokens)
    {
        return array_merge(array_slice($tokens, 0, $index), $newTokens, array_slice($tokens, $index + 1));
    }
}
