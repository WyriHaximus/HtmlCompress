<?php
namespace WyriHaximus\HtmlCompress;

class Tokens
{
    /**
     * @var Token[]
     */
    protected $tokens = [];

    public function __construct(array $tokens = [])
    {
        $this->tokens = $tokens;
    }

    /**
     * @param $index
     * @param Tokens $tokens
     */
    public function replace($index, Tokens $tokens)
    {
        $this->tokens = array_merge(
            array_slice($this->tokens, 0, $index),
            $tokens->getTokens(),
            array_slice($this->tokens, $index + 1)
        );
    }

    /**
     * @return array|Token[]
     */
    public function getTokens()
    {
        return $this->tokens;
    }

    public function getHtml()
    {
        $html = '';
        foreach ($this->tokens as $token) {
            $html .= $token->getCombinedHtml();
        }
        return $html;
    }

    public function count()
    {
        return count($this->tokens);
    }
}
