<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

final class Tokens
{
    /**
     * @var Token[]
     */
    private $tokens = [];

    /**
     * @param array|Token[] $tokens
     */
    public function __construct(array $tokens = [])
    {
        $this->tokens = $tokens;
    }

    /**
     * @param int    $index
     * @param Tokens $tokens
     */
    public function replace(int $index, Tokens $tokens)
    {
        $this->tokens = \array_merge(
            \array_slice($this->tokens, 0, $index),
            $tokens->getTokens(),
            \array_slice($this->tokens, $index + 1)
        );
    }

    /**
     * @return array|Token[]
     */
    public function getTokens(): array
    {
        return $this->tokens;
    }

    public function getHtml(): string
    {
        $html = '';
        foreach ($this->tokens as $token) {
            $html .= $token->getCombinedHtml();
        }

        return $html;
    }

    public function count(): int
    {
        return \count($this->tokens);
    }
}
