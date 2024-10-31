-- Copyright https://dev.to/yugabyte/soft-delete-cascade-in-postgresql-and-yugabytedb-166n

CREATE TABLE parent (
 parent_id int, parent_deleted timestamptz default 'infinity',
 primary key (parent_id,parent_deleted)
);

CREATE TABLE child (
 parent_id int, parent_deleted timestamptz default 'infinity',
 child_number int,
 primary key (parent_id,parent_deleted, child_number),
 foreign key (parent_id,parent_deleted)
  references parent(parent_id,parent_deleted)
  on update cascade
);

-- Views
create view valid_parent as
 select parent_id from parent where parent_deleted>=now();

create view valid_child as
 select parent_id,child_number from child where parent_deleted>=now();

-- Procedure
create procedure soft_delete_parent(id int) as $SQL$
update parent
set parent_deleted=now()
where parent_id=id;
$SQL$ language sql;

-- Run procedure
call soft_delete_parent(2);

-- Rule
create or replace rule soft_delete_parent as
on delete to valid_parent do instead
update parent
set parent_deleted=now()
where parent_id=old.parent_id;
