<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Compressor;

final class SmallestResultCompressor extends Compressor
{
    private const ZERO = 0;

    /**
     * @var CompressorInterface[]
     */
    private $compressors = [];

    public function __construct(CompressorInterface ...$compressors)
    {
        $this->compressors = $compressors;
    }

    protected function execute(string $string): string
    {
        $result = $string;
        foreach ($this->compressors as $compressor) {
            $resultLength = \strlen($result);
            $currentResult = $compressor->compress($string);
            $currentResultLength = \strlen($currentResult);

            if ($currentResultLength === self::ZERO) {
                continue;
            }

            if ($currentResultLength >= $resultLength) {
                continue;
            }

            $result = $currentResult;
        }

        return $result;
    }
}
