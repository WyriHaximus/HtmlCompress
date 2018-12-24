<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Compressor;

final class BestResultCompressor extends Compressor
{
    /**
     * @var array|Compressor[]
     */
    private $compressors = [];

    /**
     * @param array|Compressor[] $compressors
     */
    public function __construct(array $compressors)
    {
        $this->compressors = $compressors;
    }

    protected function execute(string $string): string
    {
        $result = $string;
        foreach ($this->compressors as $compressor) {
            $currentResult = $compressor->compress($string);

            if (
                \strlen($currentResult) < \strlen($result)
                &&
                \strlen($currentResult) > 0
            ) {
                $result = $currentResult;
            }
        }

        return $result;
    }
}
