package com.rnd.examples;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.annotations.Loader;
import org.hibernate.annotations.NamedQuery;
import org.hibernate.annotations.SQLDelete;
import org.hibernate.annotations.Where;

/**
 * Copyright https://vladmihalcea.com/the-best-way-to-soft-delete-with-hibernate/
 */
@Entity(name = "Tag")
@Table(name = "tag")
@SQLDelete(sql = """
    UPDATE tag
    SET deleted = true
    WHERE id = ?
    """)
@Loader(namedQuery = "findTagById")
@NamedQuery(name = "findTagById", query = """
    SELECT t
    FROM Tag t
    WHERE
        t.id = ?1 AND
        t.deleted = false
    """)
@Where(clause = "deleted = false")
public class Tag extends BaseEntity {

    @Id
    private String id;

    //Getters and setters omitted for brevity
}

class Comments {
    public static void main(String[] args) {
        // @Loader overrides the EntityManager.find()
        // @Loader is deprecated, use @SQLSelect
        // @Where is deprecated, use @SQLRestriction
        // Soft deleted entity will remain in the cache and if it’s not cleared/flushed it can be accesed by EntityManager.find()
        // EntityManager.refresh() will fail because of @SQLSelect
        // Hard delete – only via native query (see https://thorben-janssen.com/permanently-remove-when-using-soft-delete/)
    }
}
