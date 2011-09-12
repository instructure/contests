count_interpretations xs 0 0 = 0
count_interpretations [] a b = a
count_interpretations (x:[]) a b = if (isvalid_one_char x) then (a + b) else b
count_interpretations (x:y:xs) a b = count_interpretations (y:xs) new_a new_b
    where
        new_b = if (isvalid_two_char x y) then a else 0
        new_a = if (isvalid_one_char x) then (a + b) else b

isvalid_two_char x y = (num >= 1) && (num <= 26) && (x /= '0')
    where
        num = (read ("0x" ++ x:y:[])::Int)

isvalid_one_char x = (num >= 1) && (num <= 26)
    where
        num = (read ("0x" ++ x:[])::Int)

handleInput "0" = do return ()
handleInput x = do
    print $ count_interpretations x 1 0
    main

main = do
    line <- getLine
    handleInput line
