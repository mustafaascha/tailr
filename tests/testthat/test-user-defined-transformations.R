context("test-user-defined-transformations.R")

test_that("we call the default transformation function", {
    f <- function(x) x
    transformed_f <- user_transform(f)
    expect_equal(body(f), body(transformed_f))
})

test_that("we transform functions with user-defined re-writing rules", {
    my_if_else <- function(test, if_true, if_false) {
        if (test) if_true else if_false
    }
    my_if_else_transform <- function(expr) {
        test <- expr[[2]]
        if_true <- expr[[3]]
        if_false <- expr[[4]]
        rlang::expr(if (rlang::UQ(test)) rlang::UQ(if_true) else rlang::UQ(if_false))
    }
    attr(my_if_else, "tailr_transform") <- my_if_else_transform

    f <- function(x, y) my_if_else(x == y, x, f(y, y))
    transformed <- user_transform(f)
    expect_equal(body(transformed), quote(if (x == y) x else f(y, y)))
})

test_that("we can use user-defined re-writing rules from another package", {
    if (!requireNamespace("pmatch", quietly = TRUE)) {
        skip("These tests require the pmatch package to be installed")
        return()
    }

    pmatch::`:=`(llists, NIL | CONS(car, cdr:llists))

    llength <- function(llist, acc = 0) {
        pmatch::cases(
            llist,
            NIL -> acc,
            CONS(car, cdr) -> llength(cdr, acc + 1)
        )
    }
    llength <- tailr::loop_transform(llength)

    make_llist <- function(n) {
        llist <- NIL
        while (n > 0) {
            llist <- CONS(n, llist)
            n <- n - 1
        }
        llist
    }

    for (n in 0:5) {
        expect_equal(n, llength(make_llist(n)))
    }
})
