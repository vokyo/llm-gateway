-- Initial schema, following docs/PLAN.md section 6.
-- Money is stored as BIGINT in the smallest currency unit, never as a floating-point type.
-- No foreign key constraints: relations are kept by the application.
-- Query indexes are designed later (W6.5); only primary keys and the unique keys
-- needed for correctness are created here.

CREATE TABLE api_key (
    id         BIGINT      NOT NULL AUTO_INCREMENT,
    key_hash   CHAR(64)    NOT NULL COMMENT 'SHA-256 of the plaintext key, hex encoded',
    key_prefix VARCHAR(16) NOT NULL COMMENT 'first characters of the key, for display only',
    status     TINYINT     NOT NULL DEFAULT 1 COMMENT '1 = active, 0 = disabled',
    rpm_limit  INT         NOT NULL COMMENT 'requests per minute',
    tpm_limit  INT         NOT NULL COMMENT 'tokens per minute',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    UNIQUE KEY uk_api_key_key_hash (key_hash)
);

CREATE TABLE quota_account (
    api_key_id BIGINT      NOT NULL,
    balance    BIGINT      NOT NULL DEFAULT 0 COMMENT 'smallest currency unit; source of truth for the balance',
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (api_key_id)
);

CREATE TABLE recharge_log (
    id         BIGINT      NOT NULL AUTO_INCREMENT,
    api_key_id BIGINT      NOT NULL,
    amount     BIGINT      NOT NULL COMMENT 'smallest currency unit',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id)
);

CREATE TABLE usage_log (
    id                BIGINT      NOT NULL AUTO_INCREMENT,
    request_id        VARCHAR(64) NOT NULL,
    api_key_id        BIGINT      NOT NULL,
    run_id            VARCHAR(64) NULL COMMENT 'agent run id from the X-Run-Id header, if any',
    model             VARCHAR(64) NOT NULL,
    prompt_tokens     INT         NOT NULL,
    completion_tokens INT         NOT NULL,
    cost              BIGINT      NOT NULL COMMENT 'smallest currency unit',
    latency_ms        INT         NOT NULL,
    ttft_ms           INT         NULL COMMENT 'time to first token; streaming requests only',
    created_at        DATETIME(3) NOT NULL COMMENT 'when the request happened, set by the writer',
    PRIMARY KEY (id),
    UNIQUE KEY uk_usage_log_request_id (request_id)
);

CREATE TABLE model_config (
    id                BIGINT      NOT NULL AUTO_INCREMENT,
    model_name        VARCHAR(64) NOT NULL,
    input_price       BIGINT      NOT NULL COMMENT 'smallest currency unit per 1M input tokens',
    output_price      BIGINT      NOT NULL COMMENT 'smallest currency unit per 1M output tokens',
    max_output_tokens INT         NOT NULL COMMENT 'used to estimate the pre-deduction when max_tokens is absent',
    PRIMARY KEY (id),
    UNIQUE KEY uk_model_config_model_name (model_name)
);

CREATE TABLE provider (
    id          BIGINT       NOT NULL AUTO_INCREMENT,
    name        VARCHAR(64)  NOT NULL,
    base_url    VARCHAR(255) NOT NULL,
    api_key_enc VARCHAR(512) NULL COMMENT 'encrypted upstream key; empty for mock-llm',
    weight      INT          NOT NULL DEFAULT 1,
    status      TINYINT      NOT NULL DEFAULT 1 COMMENT '1 = active, 0 = disabled',
    created_at  DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at  DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    UNIQUE KEY uk_provider_name (name)
);
