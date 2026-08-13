"""create initial tables

Revision ID: 0001_create_tables
Revises: 
Create Date: 2026-04-28
"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '0001_create_tables'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'users',
        sa.Column('id', sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column('email', sa.String(length=255), nullable=False, unique=True, index=True),
        sa.Column('password_hash', sa.String(length=255), nullable=False),
        sa.Column('google_id', sa.String(length=255), nullable=True, unique=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=True),
    )

    op.create_table(
        'transactions',
        sa.Column('id', sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id'), nullable=False, index=True),
        sa.Column('merchant_name', sa.String(length=500), nullable=False),
        sa.Column('amount', sa.Float(), nullable=False),
        sa.Column('date', sa.Date(), nullable=False),
        sa.Column('category', sa.String(length=100), nullable=True),
        sa.Column('raw_description', sa.String(length=1000), nullable=True),
        sa.Column('is_debit', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=True),
    )

    op.create_table(
        'budgets',
        sa.Column('id', sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id'), nullable=False, index=True),
        sa.Column('category', sa.String(length=100), nullable=False),
        sa.Column('monthly_limit', sa.Float(), nullable=False),
        sa.Column('month_year', sa.String(length=7), nullable=False),
    )

    op.create_table(
        'goals',
        sa.Column('id', sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id'), nullable=False, index=True),
        sa.Column('name', sa.String(length=255), nullable=False),
        sa.Column('target_amount', sa.Float(), nullable=False),
        sa.Column('current_amount', sa.Float(), nullable=True),
        sa.Column('deadline', sa.Date(), nullable=True),
    )


def downgrade():
    op.drop_table('goals')
    op.drop_table('budgets')
    op.drop_table('transactions')
    op.drop_table('users')
